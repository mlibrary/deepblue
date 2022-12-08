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
                   options: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern_id=#{curation_concern_id}",
                                             "path_to_yaml_file=#{path_to_yaml_file}",
                                             "ingester=#{ingester}",
                                             "mode=#{mode}",
                                             "first_label=#{first_label}",
                                             "options=#{options}",
                                             "" ] if ingest_append_content_service_debug_verbose
      msg_handler.msg_verbose "Path to script: #{path_to_yaml_file}"
      ingest_script = IngestScript.new( curation_concern_id: curation_concern_id,
                                        ingest_mode: 'append',
                                        path_to_yaml_file: path_to_yaml_file )
      ingest_script.log = msg_handler.msg_queue
      ingest_script.save_yaml
      return false if msg_handler.msg_error_if?( !ingest_script.ingest_script_present?,
                                                 msg: "failed to load script '#{path_to_yaml_file}'" )

      bcs = IngestAppendContentService.new( ingest_script: ingest_script,
                                            msg_handler: msg_handler,
                                            options: options,
                                            ingester: ingester,
                                            first_label: first_label,
                                            mode: mode )
      bcs.run
      ingest_script.log = msg_handler.msg_queue
      ingest_script.save_yaml
      lines = bcs.email_after_msg_lines
      return if lines.blank? || msg_handler.nil?
      msg_handler.msg( lines )
    rescue Exception => e
      msg_handler.msg_error "IngestAppendContentService.call(#{path_to_yaml_file}) #{e.class}: #{e.message}"
      raise e
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
                                             "ingest_script.path_to_yaml_file=#{ingest_script.path_to_yaml_file}",
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

