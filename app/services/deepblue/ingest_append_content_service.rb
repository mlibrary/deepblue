# frozen_string_literal: true

module Deepblue

  # Given a configuration hash read from a yaml file, build the contents in the repository.
  class IngestAppendContentService < NewContentAppendService

    mattr_accessor :ingest_append_content_service_debug_verbose,
                   default: ::Deepblue::IngestIntegrationService.ingest_append_content_service_debug_verbose

    attr_accessor :first_label, :msg_handler, :mode

    def self.call( curation_concern_id:,
                   mode: 'append',
                   msg_handler:,
                   path_to_yaml_file:,
                   ingester: nil,
                   first_label: 'work_id',
                   job_json: nil,
                   options: )

      begin_timestamp = DateTime.now
      begin
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern_id=#{curation_concern_id}",
                                             "path_to_yaml_file=#{path_to_yaml_file}",
                                             "ingester=#{ingester}",
                                             "mode=#{mode}",
                                             "first_label=#{first_label}",
                                             "job_json=#{job_json}",
                                             "options=#{options}",
                                             "" ] if ingest_append_content_service_debug_verbose
      msg_handler.msg_verbose "Path to script: #{path_to_yaml_file}"
      ingest_script = IngestScript.append( curation_concern_id: curation_concern_id,
                                           initial_yaml_file_path: path_to_yaml_file )
      rescue Exception => e
        msg_handler.msg_error "IngestAppendContentService.call(#{path_to_yaml_file}) #{e.class}: #{e.message}"
        raise e
      end
      begin
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "ingest_script=#{ingest_script}",
                                               "" ] if ingest_append_content_service_debug_verbose
        ingest_script.job_begin_timestamp = begin_timestamp.to_formatted_s(:db)
        ingest_script.job_end_timestamp = ''
        ingest_script.job_run_count = 1
        ingest_script.job_file_sets_processed_count = 0
        ingest_script.job_json = job_json if ingest_append_content_service_debug_verbose
        ingest_script.job_id = job_json['job_id']
        ingest_script.log_save( msg_handler.msg_queue )
        return false if msg_handler.msg_error_if?( !ingest_script.ingest_script_present?,
                                                   msg: "failed to load script '#{path_to_yaml_file}'" )
        bcs = IngestAppendContentService.new( ingest_script: ingest_script,
                                              msg_handler: msg_handler,
                                              options: options,
                                              ingester: ingester,
                                              first_label: first_label,
                                              mode: mode )
        bcs.run
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "ingest_script=#{ingest_script}",
                                               "" ] if ingest_append_content_service_debug_verbose
        ingest_script.job_end_timestamp = DateTime.now.to_formatted_s(:db)
        ingest_script.log_save( msg_handler.msg_queue )
        ingest_script.move_to_finished if ingest_script.finished?
        lines = bcs.email_after_msg_lines
        return if lines.blank? || msg_handler.nil?
        msg_handler.msg( lines )
      rescue Exception => e
        ingest_script.log_save( msg_handler.msg_queue ) if ingest_script.present?
        msg_handler.msg_error "IngestAppendContentService.call(#{path_to_yaml_file}) #{e.class}: #{e.message}"
        raise e
      end
    end

    def self.ensure_tmp_script_dir_is_linked(debug_verbose: ingest_append_content_service_debug_verbose)
      debug_verbose = debug_verbose || ingest_append_content_service_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ], bold_puts: true if debug_verbose
      return if Rails.env.development?
      # There may be an issue when running from circleci
      begin
        current_dir = `pwd`
        current_dir.chomp!
        # ln -s /hydra-dev/deepbluedata-testing/tmp/scripts /hydra-dev/deepbluedata-testing/releases/20221213181102/tmp/scripts
        tmp_scripts_dir = File.join current_dir, 'tmp', 'scripts'
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "tmp_scripts_dir=#{tmp_scripts_dir}",
                                               "" ], bold_puts: true if debug_verbose
        link_exists = File.symlink? tmp_scripts_dir
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "link_exists=#{link_exists}",
                                               "" ], bold_puts: true if debug_verbose
        return if link_exists
        real_dir = File.dirname current_dir
        real_dir = File.join real_dir, 'tmp', 'scripts'
        FileUtils.mkdir_p real_dir unless Dir.exist? read_dir
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "real_dir=#{real_dir}",
                                               "real_dir exists?=#{File.exists? real_dir}",
                                               "" ], bold_puts: true if debug_verbose
        cmd = "ln -s \"#{real_dir}/\" \"#{tmp_scripts_dir}\""
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "cmd=#{cmd}",
                                               "" ], bold_puts: true if debug_verbose
        rv = `#{cmd}`
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "cmd rv=#{rv}",
                                               "" ], bold_puts: true if debug_verbose
        link_exists = File.symlink? tmp_scripts_dir
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "link_exists=#{link_exists}",
                                               "" ], bold_puts: true if debug_verbose
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

