# frozen_string_literal: true

class GlobusJob < ::Hyrax::ApplicationJob

  @@globus_era_timestamp = DeepBlueDocs::Application.config.globus_era_timestamp
  @@globus_era_token = DeepBlueDocs::Application.config.globus_era_token.freeze

  @@globus_enabled = DeepBlueDocs::Application.config.globus_enabled.freeze
  @@globus_base_file_name = DeepBlueDocs::Application.config.base_file_name.freeze
  @@globus_base_url = DeepBlueDocs::Application.config.globus_base_url.freeze
  @@globus_download_dir = DeepBlueDocs::Application.config.globus_download_dir.freeze
  @@globus_prep_dir = DeepBlueDocs::Application.config.globus_prep_dir.freeze

  @@globus_copy_file_group = DeepBlueDocs::Application.config.globus_copy_file_group.freeze
  @@globus_copy_file_permissions = DeepBlueDocs::Application.config.globus_copy_file_permissions.freeze

  def self.files_available?( concern_id )
    copy_complete? concern_id
  end

  def self.copy_complete?( id )
    dir = @@globus_download_dir
    dir = dir.join files_target_file_name( id )
    Dir.exist? dir
  end

  def self.clean_dir( dir_path, delete_dir: false )
    return unless Dir.exist? dir_path
    Dir.foreach( dir_path ) do |f|
      next if [ '.', '..' ].include? f
      clean_file File.join( dir_path, f )
    end
    return unless delete_dir
    Dir.delete dir_path
  end

  def self.clean_file( file_path )
    File.delete file_path if File.exist? file_path
  end

  def self.error_file( id )
    target_file_name_env( @@globus_prep_dir, 'error', target_base_name( id ) )
  end

  def self.error_file_contents( id )
    contents = nil
    return contents unless error_file_exists? id
    file = error_file id
    open( file, 'r' ) { |f| contents = f.readlines }
    return contents
  end

  def self.error_file_exists?( id, write_error_to_log: false, log_prefix: '', quiet: true )
    error_file = error_file( id )
    error_file_exists = false
    if File.exist? error_file
      if write_error_to_log
        msg = nil
        open( error_file, 'r' ) { |f| msg = f.read; msg.chomp! } # rubocop:disable Style/Semicolon
        Deepblue::LoggingHelper.debug "#{log_prefix} error file contains: #{msg}" unless quiet
      end
      error_file_exists = true
    end
    error_file_exists
  end

  def self.external_url( id )
    "#{@@globus_base_url}#{files_target_file_name(id)}%2F"
  end

  def self.files_target_file_name( id = '' )
    "#{@@globus_base_file_name}#{id}"
  end

  def self.files_prepping?( id )
    rv = !copy_complete?( id ) && locked?( id )
    rv
  end

  def self.lock( concern_id, log_prefix )
    lock_token = era_token
    lock_file = lock_file concern_id
    Deepblue::LoggingHelper.debug "#{log_prefix} writing lock token #{lock_token} to #{lock_file}" unless @globus_job_quiet
    open( lock_file, 'w' ) { |f| f << lock_token << "\n" }
    File.exist? lock_file
  end

  def self.lock_file( id = '' )
    target_file_name_env( @@globus_prep_dir, 'lock', target_base_name( id ) )
  end

  def self.locked?( concern_id, log_prefix: '', quiet: true )
    return false if error_file_exists?( concern_id, write_error_to_log: true, log_prefix: log_prefix, quiet: quiet )
    lock_file = lock_file concern_id
    return false unless File.exist? lock_file
    current_token = era_token
    lock_token = read_token lock_file
    rv = ( current_token == lock_token )
    Deepblue::LoggingHelper.debug "#{log_prefix} testing token from #{lock_file}: current_token: #{current_token} == lock_token: #{lock_token}: #{rv}" unless @quiet
    rv
  end

  def self.read_token( token_file )
    token = nil
    open( token_file, 'r' ) { |f| token = f.read.chomp! }
    return token
  end

  def self.server_prefix( str: '' )
    "#{Rails.env}#{str}"
  end

  def self.target_base_name( id = '', prefix: '', postfix: '' )
    prefix = server_prefix( str: '_' ) if prefix.nil?
    "#{prefix}#{@@globus_base_file_name}#{id}#{postfix}"
  end

  def self.target_file_name_env( dir, file_type, base_name )
    target_file_name( dir, ".#{server_prefix}.#{file_type}.#{base_name}" )
  end

  def self.target_file_name( dir, filename, ext = '' )
    return Pathname.new( filename + ext ) if dir.nil?
    dir.join( filename + ext )
  end

  def self.target_download_dir( concern_id )
    target_dir_name( @@globus_download_dir, target_base_name(concern_id ) )
  end

  def self.target_dir_name( dir, subdir, mkdir: false )
    target_dir = dir.join subdir
    if mkdir
      Dir.mkdir(target_dir ) unless Dir.exist? target_dir
    end
    target_dir
  end

  def self.target_prep_dir( concern_id, prefix: '', postfix: '', mkdir: false )
    prefix = server_prefix( str: '_' ) if prefix.nil?
    subdir = target_base_name( concern_id, prefix: prefix, postfix: postfix )
    target_dir_name( @@globus_prep_dir, subdir, mkdir: mkdir )
  end

  def self.target_prep_tmp_dir( concern_id, prefix: '', postfix: '', mkdir: false )
    prefix = server_prefix( str: '_' ) if prefix.nil?
    dir = target_prep_dir( concern_id, prefix: prefix, postfix: "#{postfix}_tmp" )
    if mkdir
      Dir.mkdir(dir ) unless Dir.exist? dir
    end
    dir
  end

  def self.era_token
    # read_token @@globus_era_file
    # read_token @@globus_era.era_file
    @@globus_era_token
  end

  def self.era_token_time
    timestamp = era_token
    Time.parse( timestamp )
  end

  # @param [String] concern_id
  # @param [String, "Globus: "] log_prefix
  def perform( concern_id, log_prefix: "Globus: " )
    @globus_concern_id = concern_id
    @globus_log_prefix = log_prefix
    @globus_lock_file = GlobusJob.lock_file concern_id
  end

  protected

    def globus_acquire_lock?
      return false if globus_locked?
      globus_lock
    end

    def globus_copy_job_complete?( concern_id )
      Dir.exist? target_download_dir2 concern_id
    end

    def globus_copy_job_email_clean
      email_file = globus_copy_job_email_file
      Deepblue::LoggingHelper.debug "#{@globus_log_prefix} globus_copy_job_email_reset exists? #{email_file}" unless @globus_job_quiet
      return unless File.exist? email_file
      Deepblue::LoggingHelper.debug "#{@globus_log_prefix} globus_copy_job_email_reset delete #{email_file}" unless @globus_job_quiet
      File.delete email_file
    end

    def globus_copy_job_email_file
      rv = GlobusJob.target_file_name_env( @@globus_prep_dir,
                                           'copy_job_emails',
                                           GlobusJob.target_base_name( @globus_concern_id ) )
      return rv
    end

    def globus_email_rds( curation_concern: nil, description: '' )
      curation_concern = ActiveFedora::Base.find @globus_concern_id if curation_concern.nil?
      return unless curation_concern.respond_to? :email_rds_globus
      curation_concern.email_rds_globus( current_user: nil, event_note: description )
    end

    def globus_error( msg )
      file = globus_error_file
      Deepblue::LoggingHelper.debug "#{@globus_log_prefix} writing error message to #{file}" unless @globus_job_quiet
      open( file, 'w' ) { |f| f << msg << "\n" }
      file
    end

    def globus_error_file
      GlobusJob.target_file_name_env( @@globus_prep_dir, 'error', GlobusJob.target_base_name( @globus_concern_id ) )
    end

    def globus_error_file_exists?( write_error_to_log: false )
      GlobusJob.error_file_exists?( @globus_concern_id,
                                    write_error_to_log: write_error_to_log,
                                    log_prefix: @globus_log_prefix,
                                    quiet: @globus_job_quiet )
    end

    def globus_error_reset
      file = globus_error_file
      File.delete file if File.exist? file
      true
    end

    def globus_file_lock( file, mode: File::LOCK_EX )
      success = true
      if File.exist? file
        success = file.flock( mode )
        if success
          begin
            yield file
          ensure
            file.flock( File::LOCK_UN )
          end
        end
      else
        yield file
      end
      return success
    end

    def globus_job_perform( concern_id: '', email: nil, log_prefix: 'Globus: ', quiet: false ) # , &globus_block )
      @globus_concern_id = concern_id
      @globus_log_prefix = log_prefix
      @globus_lock_file = nil
      @globus_job_quiet = quiet
      return unless @@globus_enabled
      begin
        if globus_job_complete?
          globus_job_perform_already_complete( email: email )
          return
        end
        @globus_lock_file = GlobusJob.lock_file @globus_concern_id
        Deepblue::LoggingHelper.debug "#{@globus_log_prefix} lock file #{@globus_lock_file}" unless @globus_job_quiet
      rescue Exception => e # rubocop:disable Lint/RescueException
        msg = "#{@globus_log_prefix} #{e.class}: #{e.message} at #{e.backtrace[0]}"
        # Rails.logger.error msg
        Rails.logger.error "#{@globus_log_prefix} #{e.class}: #{e.message} at #{e.backtrace.join("\n")}"
        globus_error msg
        return
      end
      unless globus_acquire_lock?
        globus_job_perform_in_progress( email: email )
        return
      end
      begin
        globus_error_reset
        globus_job_perform_complete_reset
        # globus_block.call
        yield if block_given?
        @globus_lock_file = globus_unlock
        globus_job_perform_complete
      rescue Exception => e # rubocop:disable Lint/RescueException
        msg = "#{@globus_log_prefix} #{e.class}: #{e.message} at #{e.backtrace[0]}"
        Rails.logger.error msg
        globus_error msg
      ensure
        globus_unlock
      end
    end

    def globus_job_perform_already_complete( email: nil )
      if email.nil?
        Deepblue::LoggingHelper.debug "#{@globus_log_prefix} skipping already complete globus job" unless @globus_job_quiet
      else
        Deepblue::LoggingHelper.debug "#{@globus_log_prefix} skipping already complete globus job, email=#{email}" unless @globus_job_quiet
      end
    end

    def globus_job_perform_in_progress( email: nil )
      if email.nil?
        Deepblue::LoggingHelper.debug "#{@globus_log_prefix} skipping in progress globus job" unless @globus_job_quiet
      else
        Deepblue::LoggingHelper.debug "#{@globus_log_prefix} skipping in progress globus job, email=#{email}" unless @globus_job_quiet
      end
    end

    def globus_job_perform_complete
      file = globus_job_complete_file
      timestamp = Time.now.to_s
      open( file, 'w' ) { |f| f << timestamp << "\n" }
      globus_error_reset
      Deepblue::LoggingHelper.debug "#{@globus_log_prefix} job complete at #{timestamp}" unless @globus_job_quiet
      return file
    end

    def globus_job_perform_complete_reset
      file = globus_job_complete_file
      File.delete file if File.exist? file
      true
    end

    def globus_lock
      GlobusJob.lock( @globus_concern_id, @globus_log_prefix )
    end

    def globus_lock_file( id = '' )
      GlobusJob.lock_file id
    end

    def globus_locked?
      GlobusJob.locked?( @globus_concern_id, log_prefix: @globus_log_prefix, quiet: @globus_job_quiet )
    end

    def globus_ready_file
      GlobusJob.target_file_name_env( @@globus_prep_dir, 'ready', GlobusJob.target_base_name( @globus_concern_id ) )
    end

    def globus_unlock
      return nil if @globus_lock_file.nil?
      return nil unless File.exist? @globus_lock_file
      Deepblue::LoggingHelper.debug "#{@globus_log_prefix} unlock by deleting file #{@globus_lock_file}" unless @globus_job_quiet
      File.delete @globus_lock_file
      nil
    end

    def target_download_dir2( concern_id )
      GlobusJob.target_download_dir( concern_id )
    end

    def target_dir_name2( dir, subdir, mkdir: false )
      GlobusJob.target_dir_name( dir, subdir, mkdir: mkdir )
    end

    def target_prep_dir2( concern_id, prefix: '', postfix: '', mkdir: false )
      GlobusJob.target_prep_dir( concern_id, prefix: prefix, postfix: postfix, mkdir: mkdir )
    end

    def target_prep_tmp_dir2( concern_id, prefix: '', postfix: '', mkdir: false )
      GlobusJob.target_prep_tmp_dir( concern_id, prefix: prefix, postfix: postfix, mkdir: mkdir )
    end

end
