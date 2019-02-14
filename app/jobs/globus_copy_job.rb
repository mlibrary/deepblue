# frozen_string_literal: true

class GlobusCopyJob < GlobusJob
  queue_as :globus_copy

  # @param [String] concern_id
  # @param [String, "Globus: " ] log_prefix
  # @param [boolean, false] generate_error
  # @param [integer, 0 ] delay_per_file_seconds
  # @param [String, nil ] user_email
  def perform( concern_id, log_prefix: "Globus: ", generate_error: false, delay_per_file_seconds: 0, user_email: nil )
    globus_job_perform( concern_id: concern_id, email: user_email, log_prefix: "#{log_prefix}globus_copy_job" ) do
      Deepblue::LoggingHelper.debug "#{@globus_log_prefix} begin copy" unless @globus_job_quiet
      @target_download_dir = target_download_dir2 @globus_concern_id
      @target_prep_dir     = target_prep_dir2( @globus_concern_id, prefix: nil, mkdir: true )
      @target_prep_dir_tmp = target_prep_tmp_dir2( @globus_concern_id, prefix: nil, mkdir: true )
      curation_concern = ActiveFedora::Base.find @globus_concern_id
      globus_email_rds( curation_concern: curation_concern, description: "copy job started for work #{curation_concern.id}" )
      metadata_file = curation_concern.metadata_report( dir: @target_prep_dir_tmp, filename_pre: 'w_' )
      move_destination = GlobusJob.target_file_name( @target_prep_dir, metadata_file.basename )
      Deepblue::LoggingHelper.debug "#{@globus_log_prefix} mv #{metadata_file} to #{move_destination}" unless @globus_job_quiet
      FileUtils.move( metadata_file, move_destination )
      file_sets = curation_concern.file_sets
      do_copy_predicate = ->(target_file_name, _target_file) { globus_do_copy?( target_file_name ) }
      Deepblue::ExportFilesHelper.export_file_sets( target_dir: @target_prep_dir_tmp,
                                                    file_sets: file_sets,
                                                    log_prefix: @globus_log_prefix,
                                                    do_export_predicate: do_copy_predicate ) do |target_file_name, target_file|
        sleep delay_per_file_seconds if delay_per_file_seconds.positive?
        move_destination = GlobusJob.target_file_name( @target_prep_dir, target_file_name )
        Deepblue::LoggingHelper.debug "#{@globus_log_prefix} mv #{target_file} to #{move_destination}" unless @globus_job_quiet
        FileUtils.chmod( @@globus_copy_file_permissions, target_file )
        FileUtils.chown( nil, @@globus_copy_file_group, target_file ) unless @@globus_copy_file_group.blank?
        FileUtils.move( target_file, move_destination )
        if generate_error
          @globus_lock_file = nil
          raise StandardError, "generated error"
        end
      end
      Deepblue::LoggingHelper.debug "#{@globus_log_prefix} mv #{@target_prep_dir} to #{@target_download_dir}" unless @globus_job_quiet
      FileUtils.move( @target_prep_dir, @target_download_dir )
      FileUtils.rmdir @target_prep_dir_tmp
      Deepblue::LoggingHelper.debug "#{@globus_log_prefix} copy complete" unless @globus_job_quiet
      begin
        globus_copy_job_email_add( user_email )
        globus_copy_job_email_add( Deepblue::EmailHelper.notification_email )
        @email_lines = globus_copy_job_complete_lines( curation_concern )
        globus_copy_job_email_all
        globus_copy_job_email_clean
      rescue Exception => e # rubocop:disable Lint/RescueException
        # msg = "#{@globus_log_prefix} #{e.class}: #{e.message} at #{e.backtrace[0]}"
        msg = "#{@globus_log_prefix} #{e.class}: #{e.message} at #{e.backtrace.join("\n")}"
        Rails.logger.error msg
      end
    end
  end

  def globus_copy_job_email_add( email = nil )
    email_file = globus_copy_job_email_file
    Deepblue::LoggingHelper.debug "#{@globus_log_prefix} globus_copy_job_email_add #{email} to #{email_file}" unless @globus_job_quiet
    open( email_file, 'a' ) do |file|
      globus_file_lock( file ) do |out|
        out << if email.nil?
                 ''
               else
                 "#{email}\n"
               end
      end
    end
  end

  protected

    @email_lines = []

    def globus_copy_job_complete_lines( curation_concern )
      lines = []
      lines << "Globus download is now available."
      lines << "Work: #{MsgHelper.title(curation_concern)}"
      lines << "At: #{MsgHelper.work_location(curation_concern: curation_concern)}"
      lines << "By: #{MsgHelper.creator(curation_concern)}"
      lines << "Deposited by: #{curation_concern.depositor}"
      lines << "Globus link: #{MsgHelper.globus_link(curation_concern)}"
      return lines
    rescue Exception => e # rubocop:disable Lint/RescueException
      # msg = "#{@globus_log_prefix} #{e.class}: #{e.message} at #{e.backtrace[0]}"
      msg = "#{@globus_log_prefix} #{e.class}: #{e.message} at #{e.backtrace.join("\n")}"
      Rails.logger.error msg
    end

    def globus_copy_job_email_user( email: nil, lines: [] )
      return if email.blank?
      return if lines.blank?
      Deepblue::LoggingHelper.debug "#{@globus_log_prefix} globus_copy_job_email_user: work id: #{@globus_concern_id} email: #{email}" unless @globus_job_quiet
      body = lines.join( "\n" )
      to = email
      from = email
      subject = 'DBD: Globus Work Files Available'
      Deepblue::EmailHelper.log( class_name: 'GlobusCopyJob',
                                 current_user: nil,
                                 event: Deepblue::AbstractEventBehavior::EVENT_GLOBUS,
                                 event_note: 'files available',
                                 id: @globus_concern_id,
                                 to: to,
                                 from: from,
                                 subject: subject,
                                 body: lines )
      Deepblue::EmailHelper.send_email( to: to, from: from, subject: subject, body: body )
    end

    def globus_copy_job_email_all( emails: nil, lines: [] )
      emails = globus_copy_job_emails if emails.blank?
      Deepblue::LoggingHelper.debug "#{@globus_log_prefix} globus_copy_job_email_all emails=#{emails}" unless @globus_job_quiet
      return if emails.count.zero?
      lines = @email_lines if lines.blank?
      Deepblue::LoggingHelper.debug "#{@globus_log_prefix} globus_copy_job_email_all lines=#{lines}" unless @globus_job_quiet
      emails.each { |email| globus_copy_job_email_user( email: email, lines: lines ) }
    rescue Exception => e # rubocop:disable Lint/RescueException
      # msg = "#{@globus_log_prefix} #{e.class}: #{e.message} at #{e.backtrace[0]}"
      msg = "#{@globus_log_prefix} #{e.class}: #{e.message} at #{e.backtrace.join("\n")}"
      Rails.logger.error msg
    end

    def globus_copy_job_emails
      email_addresses = {}
      email_file = globus_copy_job_email_file
      Deepblue::LoggingHelper.debug "#{@globus_log_prefix} globus_copy_job_emails email_file=#{email_file}" unless @globus_job_quiet
      if File.exist? email_file
        # read the file, one email address per line
        open( email_file, 'r' ) do |file|
          globus_file_lock( file, mode: File::LOCK_SH ) do |fin|
            until fin.eof?
              line = fin.readline
              line = line.chomp!
              Deepblue::LoggingHelper.debug "#{@globus_log_prefix} globus_copy_job_emails line=#{line}" unless @globus_job_quiet
              email_addresses[line] = true unless line.empty?
            end
          end
        end
      end
      return email_addresses.keys
    end

    def globus_do_copy?( target_file_name )
      prep_file_name = GlobusJob.target_file_name( @target_prep_dir, target_file_name )
      do_copy = true
      if File.exist? prep_file_name
        Deepblue::LoggingHelper.debug "#{@globus_log_prefix} skipping copy because #{prep_file_name} already exists" unless @globus_job_quiet
        do_copy = false
      end
      do_copy
    end

    def globus_job_complete?
      globus_copy_job_complete? @globus_concern_id
    end

    def globus_job_complete_file
      globus_ready_file
    end

    def globus_job_perform_in_progress( email: nil )
      globus_copy_job_email_add( email )
      super.globus_job_perform_in_progress( email: email )
    end

end
