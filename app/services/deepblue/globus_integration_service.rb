# frozen_string_literal: true

module Deepblue

  module GlobusIntegrationService

    include ::Deepblue::InitializationConstants

    @@_setup_ran = false
    @@_setup_failed = false

    def self.setup
      yield self unless @@_setup_ran
      @@_setup_ran = true
    rescue Exception => e # rubocop:disable Lint/RescueException
      @@_setup_failed = true
      msg = "#{e.class}: #{e.message} at #{e.backtrace.join("\n")}"
      # rubocop:disable Rails/Output
      puts msg
      # rubocop:enable Rails/Output
      Rails.logger.error msg
      raise e
    end

    mattr_accessor :globus_integration_service_debug_verbose, default: false

    mattr_accessor :globus_after_copy_job_ui_delay_seconds,       default: 3
    mattr_accessor :globus_base_file_name,                        default: "DeepBlueData_"
    mattr_accessor :globus_base_url,                              default: 'https://app.globus.org/file-manager?origin_id=99d8c648-a9ff-11e7-aedd-22000a92523b&origin_path=%2Fdownload%2F'
    mattr_accessor :globus_best_used_gt_size
    mattr_accessor :globus_best_used_gt_size_str
    mattr_accessor :globus_bounce_external_link_off_server,       default: true
    mattr_accessor :globus_copy_file_group
    mattr_accessor :globus_copy_file_permissions
    mattr_accessor :globus_debug_delay_per_file_copy_job_seconds, default: 0
    mattr_accessor :globus_dir
    mattr_accessor :globus_dir_modifier
    mattr_accessor :globus_download_dir
    mattr_accessor :globus_enabled,                               default: false
    mattr_accessor :globus_era_timestamp
    mattr_accessor :globus_era_token
    mattr_accessor :globus_prep_dir
    mattr_accessor :globus_restart_all_copy_jobs_quiet

    def self.globus_int_srv()
      puts "globus_int_srv"
    end

    def self.globus_errors_report( quiet: true,
                                   debug_verbose: globus_integration_service_debug_verbose,
                                   msg_handler:,
                                   rake_task: false )

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "quiet=#{quiet}",
                                             "rake_task=#{rake_task}",
                                             "" ], bold_puts: rake_task if debug_verbose
      base_name = GlobusJob.target_base_name ''
      lock_file_prefix = GlobusJob.target_file_name_env(nil, 'lock', base_name ).to_s
      lock_file_re = Regexp.compile( '^' + lock_file_prefix + '([0-9a-z-]+)' + '$' )
      error_file_prefix = GlobusJob.target_file_name_env(nil, 'error', base_name ).to_s
      error_file_re = Regexp.compile( '^' + error_file_prefix + '([0-9a-z-]+)' + '$' )
      prep_dir_prefix = GlobusJob.target_file_name( nil, "#{GlobusJob.server_prefix(str: '_')}#{base_name}" ).to_s
      prep_dir_re = Regexp.compile( '^' + prep_dir_prefix + '([0-9a-z-]+)' + '$' )
      prep_tmp_dir_re = Regexp.compile( '^' + prep_dir_prefix + '([0-9a-z-]+)_tmp' + '$' )
      # ready_file_prefix = GlobusJob.target_file_name_env(nil, 'ready', base_name ).to_s
      # ready_file_re = Regexp.compile( '^' + ready_file_prefix + '([0-9a-z-]+)' + '$' )
      starts_with_path = "#{::Deepblue::GlobusIntegrationService.globus_prep_dir}#{File::SEPARATOR}"
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "lock_file_prefix=#{lock_file_prefix}",
                                             "lock_file_re=#{lock_file_re}",
                                             "error_file_prefix=#{error_file_prefix}",
                                             "error_file_re=#{error_file_re}",
                                             "prep_dir_prefix=#{prep_dir_prefix}",
                                             "prep_dir_re=#{prep_dir_re}",
                                             "prep_tmp_dir_re=#{prep_tmp_dir_re}",
                                             # "ready_file_prefix=#{prep_dir_re}",
                                             # "ready_file_re=#{prep_tmp_dir_re}",
                                             "starts_with_path=#{starts_with_path}",
                                             "" ], bold_puts: rake_task if debug_verbose
      files = Dir.glob( "#{starts_with_path}*", File::FNM_DOTMATCH )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "files.size=#{files.size}",
                                             "" ], bold_puts: rake_task if debug_verbose
      locked_ids = {}
      error_ids = {}
      prep_dir_ids = {}
      prep_dir_tmp_ids = {}
      # ready_ids = {}
      files.each do |f|
        f1 = f
        f = f.slice( (starts_with_path.length)..(f.length) ) if f.starts_with? starts_with_path
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "processing '#{f1}'",
                                               "strip leading path '#{f}'",
                                               "" ], bold_puts: rake_task if debug_verbose
        globus_add_status( matcher: lock_file_re,
                           path: f,
                           hash: locked_ids,
                           type: 'locked',
                           msg_handler: msg_handler )
        globus_add_status( matcher: error_file_re,
                           path: f,
                           hash: error_ids,
                           type: 'error',
                           msg_handler: msg_handler )
        globus_add_status( matcher: prep_dir_re,
                           path: f,
                           hash: prep_dir_ids,
                           type: 'prep',
                           msg_handler: msg_handler )
        globus_add_status( matcher: prep_tmp_dir_re,
                           path: f,
                           hash: prep_dir_tmp_ids,
                           type: 'prep tmp',
                           msg_handler: msg_handler )
        # globus_add_status( matcher: ready_file_re,
        #                    path: f,
        #                    hash: ready_ids,
        #                    type: 'ready',
        #                    msg_handler: msg_handler )
      end
      reporter = ::Deepblue::GlobusReporter.new( error_ids: error_ids,
                                                 locked_ids: locked_ids,
                                                 prep_dir_ids: prep_dir_ids,
                                                 prep_dir_tmp_ids: prep_dir_tmp_ids,
                                                 ready_ids: nil,
                                                 debug_verbose: debug_verbose,
                                                 as_html: true,
                                                 msg_handler: msg_handler,
                                                 options: { 'quiet' => quiet })
      reporter.run
      puts reporter.out if rake_task
      return reporter
    end

    def self.globus_status( msg_handler: )
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "" ]  if msg_handler.debug_verbose
      rv = GlobusStatus.new( msg_handler: msg_handler )
      rv.populate
      return rv
    end

    def self.globus_status_report_new( msg_handler:, errors_report: false )
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "" ]  if msg_handler.debug_verbose
      rv = GlobusStatus.new( msg_handler: msg_handler, skip_ready: errors_report )
      rv.populate
      return rv.reporter
    end

    def self.globus_status_report( quiet: true,
                                   debug_verbose: globus_integration_service_debug_verbose,
                                   msg_handler:,
                                   rake_task: false )

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "quiet=#{quiet}",
                                             "rake_task=#{rake_task}",
                                             "" ], bold_puts: rake_task if debug_verbose
      base_name = GlobusJob.target_base_name ''
      lock_file_prefix = GlobusJob.target_file_name_env(nil, 'lock', base_name ).to_s
      lock_file_re = Regexp.compile( '^' + lock_file_prefix + '([0-9a-z-]+)' + '$' )
      error_file_prefix = GlobusJob.target_file_name_env(nil, 'error', base_name ).to_s
      error_file_re = Regexp.compile( '^' + error_file_prefix + '([0-9a-z-]+)' + '$' )
      prep_dir_prefix = GlobusJob.target_file_name( nil, "#{GlobusJob.server_prefix(str: '_')}#{base_name}" ).to_s
      prep_dir_re = Regexp.compile( '^' + prep_dir_prefix + '([0-9a-z-]+)' + '$' )
      prep_tmp_dir_re = Regexp.compile( '^' + prep_dir_prefix + '([0-9a-z-]+)_tmp' + '$' )
      ready_file_prefix = GlobusJob.target_file_name_env(nil, 'ready', base_name ).to_s
      ready_file_re = Regexp.compile( '^' + ready_file_prefix + '([0-9a-z-]+)' + '$' )
      starts_with_path = "#{::Deepblue::GlobusIntegrationService.globus_prep_dir}#{File::SEPARATOR}"
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "lock_file_prefix=#{lock_file_prefix}",
                                             "lock_file_re=#{lock_file_re}",
                                             "error_file_prefix=#{error_file_prefix}",
                                             "error_file_re=#{error_file_re}",
                                             "prep_dir_prefix=#{prep_dir_prefix}",
                                             "prep_dir_re=#{prep_dir_re}",
                                             "prep_tmp_dir_re=#{prep_tmp_dir_re}",
                                             "ready_file_prefix=#{prep_dir_re}",
                                             "ready_file_re=#{prep_tmp_dir_re}",
                                             "starts_with_path=#{starts_with_path}",
                                             "" ], bold_puts: rake_task if debug_verbose
      files = Dir.glob( "#{starts_with_path}*", File::FNM_DOTMATCH )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "files.size=#{files.size}",
                                             "" ], bold_puts: rake_task if debug_verbose
      locked_ids = {}
      error_ids = {}
      prep_dir_ids = {}
      prep_dir_tmp_ids = {}
      ready_ids = {}
      files.each do |f|
        f1 = f
        f = f.slice( (starts_with_path.length)..(f.length) ) if f.starts_with? starts_with_path
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "processing '#{f1}'",
                                               "strip leading path '#{f}'",
                                               "" ], bold_puts: rake_task if debug_verbose
        globus_add_status( matcher: lock_file_re,
                           path: f,
                           hash: locked_ids,
                           type: 'locked',
                           msg_handler: msg_handler )
        globus_add_status( matcher: error_file_re,
                           path: f,
                           hash: error_ids,
                           type: 'error',
                           msg_handler: msg_handler )
        globus_add_status( matcher: prep_dir_re,
                           path: f,
                           hash: prep_dir_ids,
                           type: 'prep',
                           msg_handler: msg_handler )
        globus_add_status( matcher: prep_tmp_dir_re,
                           path: f,
                           hash: prep_dir_tmp_ids,
                           type: 'prep tmp',
                           msg_handler: msg_handler )
        globus_add_status( matcher: ready_file_re,
                           path: f,
                           hash: ready_ids,
                           type: 'ready',
                           msg_handler: msg_handler )
      end
      reporter = ::Deepblue::GlobusReporter.new( error_ids: error_ids,
                                                 locked_ids: locked_ids,
                                                 prep_dir_ids: prep_dir_ids,
                                                 prep_dir_tmp_ids: prep_dir_tmp_ids,
                                                 ready_ids: ready_ids,
                                                 debug_verbose: debug_verbose,
                                                 as_html: true,
                                                 msg_handler: msg_handler,
                                                 options: { 'quiet' => quiet } )
      reporter.run
      puts reporter.out if rake_task
      return reporter
    end

    def self.globus_add_status( matcher:, path:, hash:, type:, msg_handler: )
      match = matcher.match( path )
      return false unless match
      concern_id = match[1]
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "#{type} id #{concern_id}",
                               "" ] if msg_handler.debug_verbose
      hash[concern_id] = true
      return true
    end

    def self.globus_job_complete_file( concern_id: )
      GlobusJob.target_file_name_env( ::Deepblue::GlobusIntegrationService.globus_prep_dir,
                                      'restarted',
                                      GlobusJob.target_base_name( concern_id ) )
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

    def self.last_complete_time( file )
      File.birthtime file
    end

  end

end
