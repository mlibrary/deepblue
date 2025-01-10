# frozen_string_literal: true

module Deepblue

  # Given a configuration hash read from a yaml file, build the contents in the repository.
  class IngestAppendContentService < NewContentAppendService

    mattr_accessor :ingest_append_content_service_debug_verbose,
                   default: ::Deepblue::IngestIntegrationService.ingest_append_content_service_debug_verbose

    mattr_accessor :add_job_json_to_ingest_script,
                   default: ::Deepblue::IngestIntegrationService.add_job_json_to_ingest_script

    @@bold_puts = false

    attr_accessor :first_label
    attr_accessor :mode
    attr_accessor :msg_handler

    def self.call_append( first_label: 'work_id',
                          ingest_script_path:,
                          ingester: nil,
                          job_json: nil,
                          max_appends:,
                          msg_handler:,
                          restart:,
                          run_count:,
                          options: )

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
             ::Deepblue::LoggingHelper.called_from,
             "ingest_append_content_service_debug_verbose=#{ingest_append_content_service_debug_verbose}",
             "::Deepblue::IngestIntegrationService.ingest_append_script_monitor_job_verbose=#{::Deepblue::IngestIntegrationService.ingest_append_script_monitor_job_verbose}",
             "::Deepblue::IngestIntegrationService.add_job_json_to_ingest_script=#{::Deepblue::IngestIntegrationService.add_job_json_to_ingest_script}",
             "::Deepblue::IngestIntegrationService.ingest_append_script_max_appends=#{::Deepblue::IngestIntegrationService.ingest_append_script_max_appends}",
             "::Deepblue::IngestIntegrationService.ingest_append_script_max_restarts_base=#{::Deepblue::IngestIntegrationService.ingest_append_script_max_restarts_base}",
             "::Deepblue::IngestIntegrationService.ingest_append_script_monitor_wait_duration=#{::Deepblue::IngestIntegrationService.ingest_append_script_monitor_wait_duration}",
             "" ] if ingest_append_content_service_debug_verbose
      return unless File.exist? ingest_script_path
      begin_timestamp = DateTime.now
      mode = 'append'
      ingest_script = nil
      begin
        msg_handler.msg_verbose msg_handler.here
        msg_handler.msg_verbose "ingest_script_path=#{ingest_script_path}"
        msg_handler.msg_verbose "ingester=#{ingester}"
        msg_handler.msg_verbose "max_appends=#{max_appends}"
        msg_handler.msg_verbose "run_count=#{run_count}"
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "first_label=#{first_label}",
                                               "ingest_script_path=#{ingest_script_path}",
                                               "ingester=#{ingester}",
                                               "job_json=#{job_json.pretty_inspect}",
                                               "max_appends=#{max_appends}",
                                               "restart=#{restart}",
                                               "run_count=#{run_count}",
                                               "options=#{options}",
                                               "" ] if ingest_append_content_service_debug_verbose
        ingest_script = IngestScript.append_load( ingest_script_path: ingest_script_path,
                                                  max_appends: max_appends,
                                                  run_count: run_count,
                                                  restart: restart,
                                                  source: "IngestAppendContentService.call_append" )
        ingest_script.log_indexed_save( msg_handler.msg_queue, source: self.class.name )
      rescue Exception => e
        msg_handler.msg_error "IngestAppendContentService.call_append(#{ingest_script_path}) #{e.class}: #{e.message}"
        raise e
      end
      begin
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "ingest_script=#{ingest_script}",
                                               "ingest_script.ingest_script_path=#{ingest_script&.ingest_script_path}",
                                               "" ] if ingest_append_content_service_debug_verbose
        ingest_script.job_begin_timestamp = begin_timestamp.to_formatted_s(:db)
        msg_handler.msg_verbose "job_begin_timestamp=#{ingest_script.job_begin_timestamp}"
        ingest_script.job_end_timestamp = ''
        ingest_script.job_max_appends = max_appends
        ingest_script.job_run_count = run_count
        ingest_script.job_file_sets_processed_count = 0
        ingest_script.job_json = job_json if add_job_json_to_ingest_script
        ingest_script.job_id = job_json['job_id']
        return false if msg_handler.msg_error_if?( !ingest_script.ingest_script_present?,
                                                   msg: "failed to load script '#{ingest_script_path}'" )
        bcs = IngestAppendContentService.new( ingest_script: ingest_script,
                                              msg_handler: msg_handler,
                                              options: options,
                                              ingester: ingester,
                                              first_label: first_label,
                                              mode: mode )
        bcs.run
        ingest_script.job_end_timestamp = DateTime.now.to_formatted_s(:db)
        msg_handler.msg_verbose "job_end_timestamp=#{ingest_script.job_end_timestamp}"
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "ingest_script.finished?=#{ingest_script.finished?}",
                                               "" ] if ingest_append_content_service_debug_verbose
        ingest_script.script_section[:email_after_msg_lines] = bcs.email_after_msg_lines
      rescue Exception => e
        msg_handler.msg_error "IngestAppendContentService.call_append(#{ingest_script_path}) #{e.class}: #{e.message}"
        raise e
      end
    ensure
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "about to save log to ingest script at run_count=#{run_count}",
                                             "" ] if ingest_append_content_service_debug_verbose
      ingest_script.log_indexed_save( msg_handler.msg_queue, source: self.class.name ) if ingest_script.present?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "ingest_script=#{ingest_script}",
                                             "ingest_script.ingest_script_path=#{ingest_script&.ingest_script_path}",
                                             "" ] if ingest_append_content_service_debug_verbose
    end

    def self.ensure_tmp_script_dir_is_linked(debug_verbose: ingest_append_content_service_debug_verbose)
      debug_verbose = debug_verbose || ingest_append_content_service_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ], bold_puts: @@bold_puts if debug_verbose
      # There may be an issue when running from circleci
      begin
        if Rails.env.development? || Rails.env.test?
          # just make sure directory ./tmp/scripts exists
          target_dir = './tmp/scripts'
          Dir.mkdir( target_dir ) unless Dir.exist?( target_dir )
          return
        end
        # ln -s /hydra-dev/deepbluedata-testing/shared/tmp/scripts /hydra-dev/deepbluedata-testing/releases/20221213181102/tmp/scripts
        current_dir = `pwd`
        current_dir.chomp!
        # current_dir will be something like: /hydra-dev/deepbluedata-testing/releases/20221213181102/
        #                                 or: /deepbluedata-prod/deepbluedata-production/20221213181102/
        # want the target dir to be: /hydra-dev/deepbluedata-testing/shared/tmp/scripts
        #                        or: /deepbluedata-prod/deepbluedata-production/shared/tmp/scripts
        current_dir.chomp!
        real_dir = File.dirname current_dir
        real_dir = File.join( real_dir, 'shared', 'tmp', 'scripts')
        FileUtilsHelper.mkdir_p( real_dir ) unless FileUtilsHelper.dir_exist?( real_dir )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "real_dir=#{real_dir}",
                                               "real_dir exists?=#{File.exist? real_dir}",
                                               "" ], bold_puts: @@bold_puts if debug_verbose

        tmp_scripts_dir = File.join current_dir, 'tmp', 'scripts'
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "tmp_scripts_dir=#{tmp_scripts_dir}",
                                               "" ], bold_puts: @@bold_puts if debug_verbose
        link_exists = File.symlink? tmp_scripts_dir
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "link_exists=#{link_exists}",
                                               "" ], bold_puts: @@bold_puts if debug_verbose
        return if link_exists
        cmd = "ln -s \"#{real_dir}/\" \"#{tmp_scripts_dir}\""
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "cmd=#{cmd}",
                                               "" ], bold_puts: @@bold_puts if debug_verbose
        rv = `#{cmd}`
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "cmd rv=#{rv}",
                                               "" ], bold_puts: @@bold_puts if debug_verbose
        link_exists = File.symlink? tmp_scripts_dir
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "link_exists=#{link_exists}",
                                               "" ], bold_puts: @@bold_puts if debug_verbose
        return
      rescue Exception => e
        puts "Exception: #{e.to_s}"
        puts e.backtrace.join("\n")
      end
    end

    def initialize( ingest_script:,
                    msg_handler:,
                    options:,
                    ingester:,
                    mode: 'append',
                    first_label: )

      @first_label = first_label
      @mode = mode
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "ingest_script.curation_concern_id=#{ingest_script.curation_concern_id}",
                                             "ingest_script.base_path=#{ingest_script.base_path}",
                                             "ingest_script.initial_yaml_file_path=#{ingest_script.initial_yaml_file_path}",
                                             "options=#{options}",
                                             "ingester=#{ingester}",
                                             "mode=#{mode}",
                                             "first_label=#{first_label}",
                                             "" ] if ingest_append_content_service_debug_verbose
      initialize_with( ingest_script: ingest_script,
                       msg_handler: msg_handler,
                       options: options,
                       ingester: ingester,
                       mode: mode )
    end

    protected

    def build_repo_contents
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "Starting build_repo_contents...",
                                             "" ] if ingest_append_content_service_debug_verbose
      do_email_before
      # user = find_or_create_user
      case mode
      when 'append'
        find_works_and_add_files
      when 'populate'
        build_works
        build_collections
      else
        find_works_and_add_files
      end
      # build_collections
      report_measurements( first_label: @first_label )
      do_email_after
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "Finished build_repo_contents.",
                                             "" ] if ingest_append_content_service_debug_verbose
    end

  end

end

