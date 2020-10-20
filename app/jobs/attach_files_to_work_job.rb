# frozen_string_literal: true

# Converts UploadedFiles into FileSets and attaches them to works.
class AttachFilesToWorkJob < ::Hyrax::ApplicationJob
  include Rails.application.routes.url_helpers
  queue_as Hyrax.config.ingest_queue_name

  ATTACH_FILES_TO_WORK_JOB_DEBUG_VERBOSE = ::Deepblue::IngestIntegrationService.attach_files_to_work_job_debug_verbose
  ATTACH_FILES_TO_WORK_UPLOAD_FILES_ASYNCHRONOUSLY = ::Deepblue::IngestIntegrationService.attach_files_to_work_upload_files_asynchronously

  attr_accessor :depositor,
                :job_status,
                :processed,
                :uploaded_files,
                :uploaded_file_ids,
                :user,
                :user_key,
                :work,
                :work_attributes

  def depositor
    @depositor ||= work_proxy_or_depositor
  end

  def job_status
    @job_status ||= job_status_init
  end

  def job_status_init
    user_id = user.id if user.present?
    main_cc_id = work.id if work.present?
    status = IngestJobStatus.find_or_create_job_started( job: self,
                                                         verbose: ATTACH_FILES_TO_WORK_JOB_DEBUG_VERBOSE,
                                                         main_cc_id: main_cc_id,
                                                         user_id: user_id )
    @processed = []
    status.processed_uploaded_file_ids.each_with_index do |uploaded_file_id,index|
      @processed << @uploaded_files[index]
    end
    return status
  end

  def processed
    @processed ||= []
  end

  def uploaded_file_ids
    @uploaded_file_ids ||= uploaded_files.map { |u| u.id }
  end

  def user
    # @user ||= User.find_by_user_key( depositor ) # Wrong!, it's actually on the upload file record.
    @user ||= User.find_by_user_key( user_key )
  end

  # @param [ActiveFedora::Base] work - the work object
  # @param [Array<Hyrax::UploadedFile>] uploaded_files - an array of files to attach
  def perform( work, uploaded_files, user_key, **work_attributes )
    @work = work
    @user_key = user_key
    @uploaded_files = Array( uploaded_files )
    @work_attributes = work_attributes
    return if job_status.finished?
    # job_status.add_message!( "#{self.class.name}.perform" ) if job_status.verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "work=#{work}",
                                           "user_key=#{user_key}",
                                           "uploaded_files=#{uploaded_files}",
                                           "uploaded_files.count=#{uploaded_files.count}",
                                           "work_attributes=#{work_attributes}",
                                           "job_status=#{job_status}",
                                           "processed=#{processed}",
                                           "" ] if ATTACH_FILES_TO_WORK_JOB_DEBUG_VERBOSE
    perform_log_starting unless job_status.did_log_starting?
    perform_validate_files unless job_status.did_validate_files?
    perform_upload_files unless job_status.did_upload_files?
    perform_notify unless job_status.did_notify?
    job_status.finished!
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "work.id=#{work.id}",
                                           "user_key=#{user_key}",
                                           "uploaded_files=#{uploaded_files}",
                                           "uploaded_files.count=#{uploaded_files.count}",
                                           "work_attributes=#{work_attributes}",
                                           "processed=#{processed}",
                                           "job_status=#{job_status}",
                                           "job_status.job_id=#{job_status.job_id}",
                                           "job_status.job_class=#{job_status.job_class}",
                                           "job_status.status=#{job_status.status}",
                                           "job_status.state=#{job_status.state}",
                                           "job_status.message=#{job_status.message}",
                                           "job_status.error=#{job_status.error}",
                                           "" ] if ATTACH_FILES_TO_WORK_JOB_DEBUG_VERBOSE
  rescue Exception => e # rubocop:disable Lint/RescueException
    msg = "#{e.class} work_id=#{work.id} -- #{e.message} at #{e.backtrace[0]}"
    Rails.logger.error msg
    job_status = JobStatus.find_or_create( job: self )
    job_status.add_error! msg
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "work.id=#{work.id}",
                                           "user_key=#{user_key}",
                                           "uploaded_files=#{uploaded_files}",
                                           "uploaded_files.count=#{uploaded_files.count}",
                                           "work_attributes=#{work_attributes}",
                                           "processed=#{processed}",
                                           "job_status=#{job_status}",
                                           "job_status.job_id=#{job_status.job_id}",
                                           "job_status.job_class=#{job_status.job_class}",
                                           "job_status.status=#{job_status.status}",
                                           "job_status.state=#{job_status.state}",
                                           "job_status.message=#{job_status.message}",
                                           "job_status.error=#{job_status.error}",
                                           "" ] if ATTACH_FILES_TO_WORK_JOB_DEBUG_VERBOSE
    ::Deepblue::UploadHelper.log( class_name: self.class.name,
                                  event: "attach_files_to_work",
                                  event_note: "failed",
                                  id: work.id,
                                  user: user.to_s,
                                  work_id: work.id,
                                  exception: e.to_s,
                                  backtrace0: e.backtrace[0],
                                  asynchronous: ATTACH_FILES_TO_WORK_UPLOAD_FILES_ASYNCHRONOUSLY )
    raise
  end

  private

    def attach_files_to_work_job_complete_email_user( email: nil, lines: [], subject: )
      return if email.blank?
      return if lines.blank?
      # Deepblue::LoggingHelper.debug "attach_files_to_work_job_complete_email_user: work id: #{work.id} email: #{email}"
      body = lines.join( "\n" )
      to = email
      from = ::Deepblue::EmailHelper.notification_email_from
      email_sent = ::Deepblue::EmailHelper.send_email( to: to,
                                                       from: from,
                                                       subject: subject,
                                                       body: body,
                                                       content_type: "text/html" )
      ::Deepblue::EmailHelper.log( class_name: self.class.name,
                                   current_user: nil,
                                   event: Deepblue::AbstractEventBehavior::EVENT_UPLOAD,
                                   event_note: 'files attached to work',
                                   id: work.id,
                                   to: to,
                                   from: from,
                                   subject: subject,
                                   body: lines,
                                   email_sent: email_sent )
    end

    def data_set_url
      Deepblue::EmailHelper.data_set_url( data_set: work )
    rescue Exception => e # rubocop:disable Lint/RescueException
      log_error "#{e.class} #{e.message} at #{e.backtrace[0]}"
      return e.to_s
    end

    def file_stats( uploaded_file )
      file_set_id = ActiveFedora::Base.uri_to_id uploaded_file.file_set_uri
      file_set = FileSet.find file_set_id
      return file_set.original_name_value, file_set.file_size_value
    rescue Exception => e # rubocop:disable Lint/RescueException
      log_error "#{e.class} #{e.message} at #{e.backtrace[0]}"
      return e.to_s, ''
    end

    def log_error( msg )
      job_status.reload
      Rails.logger.error msg
      job_status.add_error! msg
    end

    def notify_attach_files_to_work_job_complete( failed_to_upload: )
      notify_user = DeepBlueDocs::Application.config.notify_user_file_upload_and_ingest_are_complete
      notify_managers = DeepBlueDocs::Application.config.notify_managers_file_upload_and_ingest_are_complete
      return unless notify_user || notify_managers
      work_depositor = ::Deepblue::EmailHelper.cc_depositor( curation_concern: work )
      title = ::Deepblue::EmailHelper.cc_title curation_concern: work
      lines = []
      file_count = processed.size
      file_count_phrase = if 1 == file_count
                            ::Deepblue::EmailHelper.t( "hyrax.email.notify_attach_files_to_work_job_complete.one_file_count_phrase" )
                          else
                            ::Deepblue::EmailHelper.t( "hyrax.email.notify_attach_files_to_work_job_complete.many_files_count_phrase",
                                                     file_count: file_count )
                          end
      work_url = data_set_url
      lines << ::Deepblue::EmailHelper.t( "hyrax.email.notify_attach_files_to_work_job_complete.finished_html",
                                          depositor: work_depositor,
                                          file_count_phrase: file_count_phrase,
                                          title: ::Deepblue::EmailHelper.escape_html( title ),
                                          work_url: work_url )

      unless failed_to_upload.empty?
        lines << ::Deepblue::EmailHelper.t( "hyrax.email.notify_attach_files_to_work_job_complete.total_failed_html",
                                            file_count: failed_to_upload.size )
        lines << ::Deepblue::EmailHelper.t( "hyrax.email.notify_attach_files_to_work_job_complete.files_failed_html" )
        lines << "<ol>"
        failed_to_upload.each do |uploaded_file|
          file_name, file_size = file_stats( uploaded_file )
          lines << Deepblue::EmailHelper.t( "hyrax.email.notify_attach_files_to_work_job_complete.file_line_html",
                                            file_name: ::Deepblue::EmailHelper.escape_html( file_name ),
                                            file_size: file_size )
        end
        lines << "</ol>"
      end
      file_list = []
      processed.each do |uploaded_file|
        file_name, file_size = file_stats( uploaded_file )
        file_list << ::Deepblue::EmailHelper.t( "hyrax.email.notify_attach_files_to_work_job_complete.file_list_item_html",
                                                file_name: ::Deepblue::EmailHelper.escape_html( file_name ),
                                                file_size: file_size )
      end
      file_list.sort!
      lines << "<ol>"
      file_list.each do |file_item|
        lines << ::Deepblue::EmailHelper.t( "hyrax.email.notify_attach_files_to_work_job_complete.file_list_line_html",
                                            file_item: file_item )
      end
      lines << "</ol>"
      lines << ::Deepblue::EmailHelper.t( "hyrax.email.notify_attach_files_to_work_job_complete.signature_html",
                                          contact_us_at: ::Deepblue::EmailHelper.contact_us_at )
      subject = Deepblue::EmailHelper.t( "hyrax.email.notify_attach_files_to_work_job_complete.subject", title: title )
      attach_files_to_work_job_complete_email_user( email: user.email,
                                                    lines: lines,
                                                    subject: subject ) if notify_user
      attach_files_to_work_job_complete_email_user( email: Deepblue::EmailHelper.notification_email_to,
                                                    lines: lines,
                                                    subject: subject + " (RDS)" ) if notify_managers
      ::Deepblue::JiraHelper.jira_add_comment( curation_concern: work,
                                               event: "Attach Files to Work",
                                               comment: lines.join( "\n" ) )
    rescue Exception => e # rubocop:disable Lint/RescueException
      log_error "#{e.class} #{e.message} at #{e.backtrace[0]}"
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from ] + e.backtrace[0..10]
    end

    def perform_attach_to_work( actor:, uploaded_file: )
      return if job_status.did_attach_file_to_work?
      actor.attach_to_work( work, uploaded_file_id: uploaded_file_id_for( uploaded_file ), job_status: job_status )
      uploaded_file.update( file_set_uri: actor.file_set.uri )
    end

    def perform_create_content( actor:, uploaded_file: )
      # when actor.create content is here, and the processing is synchronous, then it fails to add size to the file_set
      # actor.create_content( uploaded_file, continue_job_chain_later: ATTACH_FILES_TO_WORK_UPLOAD_FILES_ASYNCHRONOUSLY )
      actor.create_content( uploaded_file,
                            continue_job_chain_later: ATTACH_FILES_TO_WORK_UPLOAD_FILES_ASYNCHRONOUSLY,
                            uploaded_file_ids: uploaded_file_ids,
                            job_status: job_status )
    end

    def perform_create_label( actor:, uploaded_file: )
      actor.create_label( file: uploaded_file )
    end

    def perform_create_metadata( actor:, metadata: )
      actor.create_metadata( metadata )
    end

    def perform_log_starting
      ::Deepblue::UploadHelper.log( class_name: self.class.name,
                                    event: "attach_files_to_work",
                                    event_note: "starting",
                                    id: work.id,
                                    uploaded_file_ids: uploaded_file_ids,
                                    uploaded_file_ids_count: uploaded_file_ids.size,
                                    user: user.to_s,
                                    work_id: work.id,
                                    work_file_set_count: work.file_set_ids.count,
                                    asynchronous: ATTACH_FILES_TO_WORK_UPLOAD_FILES_ASYNCHRONOUSLY)
      # job_status.add_message( "#{self.class.name}.perform_log_starting" ) if job_status.verbose
      job_status.did_log_starting!
    end

    def perform_notify
      failed = uploaded_files - processed
      if failed.empty?
        ::Deepblue::UploadHelper.log( class_name: self.class.name,
                                      event: "attach_files_to_work",
                                      event_note: "finished",
                                      id: work.id,
                                      uploaded_file_ids: uploaded_file_ids,
                                      uploaded_file_ids_count: uploaded_file_ids.size,
                                      user: user.to_s,
                                      work_id: work.id,
                                      work_file_set_count: work.file_set_ids.count,
                                      asynchronous: ATTACH_FILES_TO_WORK_UPLOAD_FILES_ASYNCHRONOUSLY)
      else
        Rails.logger.error "FAILED to process all uploaded files at #{caller_locations(1, 1)[0]},"\
                           " count of unprocessed files = #{failed.count}"
        ::Deepblue::UploadHelper.log( class_name: self.class.name,
                                      event: "attach_files_to_work",
                                      event_note: "finished_with_failed_files",
                                      id: work.id,
                                      uploaded_file_ids: uploaded_file_ids,
                                      uploaded_file_ids_count: uploaded_file_ids.size,
                                      user: user.to_s,
                                      work_id: work.id,
                                      work_file_set_count: work.file_set_ids.count,
                                      failed: failed,
                                      asynchronous: ATTACH_FILES_TO_WORK_UPLOAD_FILES_ASYNCHRONOUSLY )
      end
      # job_status.add_message!( "#{self.class.name}.perform_notify" ) if job_status.verbose
      notify_attach_files_to_work_job_complete( failed_to_upload: failed )
      job_status.did_notify!
    end

    def perform_upload_files
      # job_status.add_message!( "#{self.class.name}.perform_upload_files" ) if job_status.verbose
      unless job_status.uploading_files?
        job_status.uploading_files!
      end
      work_permissions = work.permissions.map( &:to_hash )
      metadata = visibility_attributes( work_attributes )
      uploaded_files.each do |uploaded_file|
        upload_file( uploaded_file, work_permissions, metadata ) unless processed_uploaded_file? uploaded_file
      end
      job_status.did_upload_files!
    end

    def perform_validate_files
      uploaded_files.each do |uploaded_file|
        next if uploaded_file.is_a? Hyrax::UploadedFile
        msg = "Hyrax::UploadedFile required, but #{uploaded_file.class} received: #{uploaded_file.inspect}"
        Rails.logger.error msg
        raise ArgumentError, msg
      end
      job_status.did_validate_files!
    end

    def processed_uploaded_file( uploaded_file )
      uploaded_file_id = uploaded_file_id_for( uploaded_file )
      job_status.processed_uploaded_file_ids << uploaded_file_id
      job_status.uploading_files! message: "processed uploaded_file: #{uploaded_file_id}"
    end

    def processed_uploaded_file?( uploaded_file )
      job_status.processed_uploaded_file_ids.include? uploaded_file_id_for( uploaded_file )
    end

    def upload_file( uploaded_file, work_permissions, metadata )
      # job_status.add_message!( "#{self.class.name}.upload_file #{uploaded_file.id}" ) if job_status.verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "work.id=#{work.id}",
                                             "uploaded_file.file=#{uploaded_file.file.path}",
                                             "uploaded_file.file_set_uri=#{uploaded_file.file_set_uri}",
                                             "uploaded_file.id=#{uploaded_file_id_for( uploaded_file )}",
                                             "user=#{user}",
                                             "work_permissions=#{work_permissions}",
                                             "metadata=#{metadata}",
                                             "uploaded_file_ids=#{uploaded_file_ids}",
                                             "" ] if ATTACH_FILES_TO_WORK_JOB_DEBUG_VERBOSE
      ::Deepblue::UploadHelper.log( class_name: self.class.name,
                                    event: "upload_file",
                                    id: "NA",
                                    path: ::Deepblue::UploadHelper.uploaded_file_path( uploaded_file ),
                                    size: ::Deepblue::UploadHelper.uploaded_file_size( uploaded_file ),
                                    uploaded_file_id: ::Deepblue::UploadHelper.uploaded_file_id( uploaded_file ),
                                    user: user.to_s,
                                    work_id: work.id,
                                    work_file_set_count: work.file_set_ids.count,
                                    asynchronous: ATTACH_FILES_TO_WORK_UPLOAD_FILES_ASYNCHRONOUSLY)
      file_set = FileSet.create
      actor = Hyrax::Actors::FileSetActor.new( file_set, user )
      actor.file_set.permissions_attributes = work_permissions
      perform_create_metadata( actor: actor, metadata: metadata )
      perform_create_label( actor: actor, uploaded_file: uploaded_file )
      perform_attach_to_work( actor: actor, uploaded_file: uploaded_file )
      perform_create_content( actor: actor, uploaded_file: uploaded_file )
      processed_uploaded_file uploaded_file
    rescue Exception => e # rubocop:disable Lint/RescueException
      log_error "#{e.class} work.id=#{work.id} -- #{e.message} at #{e.backtrace[0]}"
      file_size = File.size( uploaded_file.file.path ) rescue -1 # in case the file has already disappeared
      ::Deepblue::UploadHelper.log( class_name: self.class.name,
                                    event: "upload_file",
                                    event_note: "failed",
                                    id: work.id,
                                    path: uploaded_file.file.path,
                                    size: file_size,
                                    user: user,
                                    work_id: work.id,
                                    exception: e.to_s,
                                    backtrace0: e.backtrace[0],
                                    asynchronous: ATTACH_FILES_TO_WORK_UPLOAD_FILES_ASYNCHRONOUSLY )
    end

    def uploaded_file_id_for( uploaded_file )
      ::Deepblue::UploadHelper.uploaded_file_id( uploaded_file )
    end

    # The attributes used for visibility - sent as initial params to created FileSets.
    def visibility_attributes( attributes )
      attributes.slice( :visibility,
                        :visibility_during_lease,
                        :visibility_after_lease,
                        :lease_expiration_date,
                        :embargo_release_date,
                        :visibility_during_embargo,
                        :visibility_after_embargo )
    end

    ##
    # A work with files attached by a proxy user will set the depositor as the intended user
    # that the proxy was depositing on behalf of. See tickets #2764, #2902.
    def work_proxy_or_depositor
      work.on_behalf_of.blank? ? work.depositor : work.on_behalf_of
    end

end
