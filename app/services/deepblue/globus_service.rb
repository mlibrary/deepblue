# frozen_string_literal: true

module Deepblue

  module GlobusService

    def self.get_du( path: )
      path = path.to_s # in case its a Pathname
      return ['N/A', path] unless File.exist? path
      cmd = "du -sh #{path}"
      rv = `#{cmd}`
      rv = Array( rv.chomp.split( "\t" ) )
      rv.unshift( 'N/A' ) if rv.size < 2 # prepend
      rv
    end

    def self.get_du2( paths: )
      paths = Array( paths )
      rv = []
      paths.each { |path|  rv << get_du(path: path) }
      return rv.flatten
    end

    def self.globus_copy_complete?( id )
      return false unless globus_enabled?
      return true unless globus_export?
      dir = ::Deepblue::GlobusIntegrationService.globus_download_dir
      dir = dir.join globus_files_target_file_name( id )
      Dir.exist? dir
    end

    def self.globus_data_den_files_available?( id )
      return false unless ::Deepblue::GlobusIntegrationService.globus_use_data_den
      # TODO: use id to figure out path, and check for existence
      return false
    end

    def self.globus_download_dir_du( concern_id: )
      dir = globus_target_download_dir( concern_id )
      rv = get_du( path: dir ).first
      rv
    end

    def self.globus_error_file( id )
      globus_target_file_name_env( ::Deepblue::GlobusIntegrationService.globus_prep_dir,
                                   'error',
                                   globus_target_base_name( id ) )
    end

    def self.globus_error_file_contents( id )
      contents = nil
      return contents unless globus_error_file_exists? id
      file = globus_error_file id
      File.open( file, 'r' ) { |f| contents = f.readlines }
      return contents
    end

    def self.globus_error_file_exists?( id, write_error_to_log: false, log_prefix: '', quiet: true )
      return false if globus_use_data_den?
      error_file = globus_error_file( id )
      error_file_exists = false
      if File.exist? error_file
        if write_error_to_log
          msg = nil
          File.open( error_file, 'r' ) { |f| msg = f.read; msg.chomp! } # rubocop:disable Style/Semicolon
          ::Deepblue::LoggingHelper.debug "#{log_prefix} error file contains: #{msg}" unless quiet
        end
        error_file_exists = true
      end
      error_file_exists
    end

    def self.globus_external_url( id )
      globus_base_url = ::Deepblue::GlobusIntegrationService.globus_base_url
      globus_dir_modifier = ::Deepblue::GlobusIntegrationService.globus_dir_modifier
      file_name = globus_files_target_file_name(id)
      return "#{globus_base_url}#{globus_dir_modifier}%2F#{file_name}%2F" if globus_dir_modifier.present?
      "#{globus_base_url}#{globus_files_target_file_name(id)}%2F"
    end

    def self.globus_enabled?
      return ::Deepblue::GlobusIntegrationService.globus_enabled
    end

    def self.globus_export?
      return ::Deepblue::GlobusIntegrationService.globus_export
    end

    def self.globus_use_data_den?
      return ::Deepblue::GlobusIntegrationService.globus_use_data_den
    end

    def self.globus_files_available?( concern_id )
      return false unless globus_enabled?
      return globus_copy_complete?( concern_id ) if globus_export?
      return globus_data_den_files_available?( concern_id )
    end

    def self.globus_files_prepping?( id )
      return false unless globus_export?
      rv = !globus_copy_complete?( id ) && globus_locked?( id )
      rv
    end

    def self.globus_files_target_file_name( id = '' )
      "#{::Deepblue::GlobusIntegrationService.globus_base_file_name}#{id}"
    end

    def self.globus_job_complete?( concern_id:, debug_verbose: globus_integration_service_debug_verbose )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "concern_id=#{concern_id}",
                                             "" ] if debug_verbose
      file = globus_job_complete_file( concern_id: concern_id )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "file=#{file}",
                                             "" ] if debug_verbose
      return false unless File.exist? file
      last_complete_time = last_complete_time file
      token_time = ::GlobusJob.era_token_time
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "token_time.class.name=#{token_time.class.name}",
                                             "token_time=#{token_time} <= last_complete_time=#{last_complete_time}",
                                             "" ] if debug_verbose
      token_time <= last_complete_time
    end

    def self.globus_job_complete_file( concern_id: )
      globus_target_file_name_env( ::Deepblue::GlobusIntegrationService.globus_prep_dir,
                                   'restarted',
                                   globus_target_base_name( concern_id ) )
    end

    def self.globus_lock_file( id = '' )
      globus_target_file_name_env( ::Deepblue::GlobusIntegrationService.globus_prep_dir,
                                   'lock',
                                   globus_target_base_name( id ) )
    end

    def self.globus_locked?( concern_id, log_prefix: '', quiet: true )
      return false if globus_error_file_exists?( concern_id,
                                                 write_error_to_log: true,
                                                 log_prefix: log_prefix,
                                                 quiet: quiet )
      lock_file = globus_lock_file concern_id
      return false unless File.exist? lock_file
      current_token = ::GlobusJob.era_token
      lock_token = globus_read_token lock_file
      rv = ( current_token == lock_token )
      ::Deepblue::LoggingHelper.debug "#{log_prefix} testing token from #{lock_file}: current_token: #{current_token} == lock_token: #{lock_token}: #{rv}" unless @quiet
      rv
    end

    def self.globus_prep_dir_du( concern_id: )
      dir = globus_target_prep_dir( concern_id )
      return get_du( path: dir ).first if File.exist? dir
      dir = globus_target_prep_dir( concern_id, prefix: nil )
      rv = get_du( path: dir ).first
      # get_du2( paths: [globus_target_prep_dir( concern_id ), globus_target_prep_dir( concern_id, prefix: nil )] )
      rv
    end

    def self.globus_prep_tmp_dir_du( concern_id: )
      dir = globus_target_prep_tmp_dir( concern_id )
      return get_du( path: dir ).first if File.exist? dir
      dir = globus_target_prep_tmp_dir( concern_id, prefix: nil )
      rv = get_du( path: dir ).first
      # get_du2( paths: [globus_target_prep_tmp_dir( concern_id ), globus_target_prep_tmp_dir( concern_id, prefix: nil )] )
      rv
    end

    def self.globus_read_token( token_file )
      token = nil
      File.open( token_file, 'r' ) { |f| token = f.read.chomp! }
      return token
    end

    def self.globus_status( include_disk_usage: true, msg_handler: )
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "" ]  if msg_handler.debug_verbose
      rv = GlobusStatus.new( include_disk_usage: include_disk_usage, msg_handler: msg_handler )
      rv.populate
      return rv
    end

    def self.globus_status_compact( concern_id: )
      avail = globus_files_available?( concern_id ) ? 'R' : '-'
      error = globus_error_file_exists?( concern_id ) ? 'E' : '-'
      lock = globus_locked?( concern_id ) ? 'L' : '-'
      prep = globus_files_prepping?( concern_id ) ? 'P' : '-'
      "[#{avail}#{lock}#{prep}#{error}]"
    end

    def self.globus_status_report( msg_handler:, errors_report: false )
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "" ]  if msg_handler.debug_verbose
      rv = GlobusStatus.new( msg_handler: msg_handler, skip_ready: errors_report, auto_populate: false )
      rv.populate
      return rv.reporter
    end

    def self.globus_target_base_name( id = '', prefix: '', postfix: '' )
      prefix = server_prefix( str: '_' ) if prefix.nil?
      "#{prefix}#{::Deepblue::GlobusIntegrationService.globus_base_file_name}#{id}#{postfix}"
    end

    def self.globus_target_download_dir( concern_id )
      globus_target_dir_name( ::Deepblue::GlobusIntegrationService.globus_download_dir,
                              globus_target_base_name(concern_id) )
    end

    def self.globus_target_dir_name( dir, subdir, mkdir: false )
      if dir.is_a? String
        target_dir = File.join dir, subdir
      else
        target_dir = dir.join subdir
      end
      ::Deepblue::DiskUtilitiesHelper.mkdir( target_dir ) if mkdir
      target_dir
    end

    def self.globus_target_file_name( dir, filename, ext = '' )
      return Pathname.new( filename + ext ) if dir.nil?
      if dir.is_a? String
        rv = File.join dir, filename + ext
      else
        rv = dir.join( filename + ext )
      end
      return rv
    end

    def self.globus_target_file_name_env( dir, file_type, base_name )
      globus_target_file_name( dir, ".#{server_prefix}.#{file_type}.#{base_name}" )
    end

    def self.globus_target_prep_dir( concern_id, prefix: '', postfix: '', mkdir: false )
      prefix = server_prefix( str: '_' ) if prefix.nil?
      subdir = globus_target_base_name( concern_id, prefix: prefix, postfix: postfix )
      globus_target_dir_name( ::Deepblue::GlobusIntegrationService.globus_prep_dir, subdir, mkdir: mkdir )
    end

    def self.globus_target_prep_tmp_dir( concern_id, prefix: '', postfix: '', mkdir: false )
      prefix = server_prefix( str: '_' ) if prefix.nil?
      dir = globus_target_prep_dir( concern_id, prefix: prefix, postfix: "#{postfix}_tmp" )
      ::Deepblue::DiskUtilitiesHelper.mkdir( dir ) if mkdir
      dir
    end

    def self.last_complete_time( file )
      File.birthtime file
    end

    def self.server_prefix( str: '' )
      "#{Rails.env}#{str}"
    end

  end

end
