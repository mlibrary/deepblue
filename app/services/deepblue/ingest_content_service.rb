# frozen_string_literal: true

module Deepblue

  require_relative '../../../lib/tasks/new_content_service'

  # Given a configuration hash read from a yaml file, build the contents in the repository.
  class IngestContentService < NewContentService

    mattr_accessor :ingest_content_service_debug_verbose,
                   default: ::Deepblue::IngestIntegrationService.ingest_content_service_debug_verbose

    attr_accessor :first_label, :msg_handler, :mode

    def self.call( msg_handler:, path_to_yaml_file:, ingester: nil, mode: nil, first_label: 'work_id', options: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "path_to_yaml_file=#{path_to_yaml_file}",
                                             "ingester=#{ingester}",
                                             "mode=#{mode}",
                                             "first_label=#{first_label}",
                                             "options=#{options}",
                                             "" ] if ingest_content_service_debug_verbose
      msg_handler.msg_verbose "Path to script: #{path_to_script}"
      cfg_hash = ::Deepblue::NewContentService.load_yaml_file( path_to_yaml_file )
      return false if msg_handler.msg_error_if?( (cfg_hash.nil? || cfg_hash.empty?),
                                                 msg: "failed ot load script '#{path_to_script}'" )
      # return false if cfg_hash.nil? || cfg_hash.empty?
      base_path = File.dirname( path_to_yaml_file )
      bcs = IngestContentService.new( options: options,
                                      msg_handler: msg_handler,
                                      path_to_yaml_file: path_to_yaml_file,
                                      cfg_hash: cfg_hash,
                                      ingester: ingester,
                                      first_label: first_label,
                                      mode: mode,
                                      base_path: base_path )
      bcs.run
      lines = email_after_msg_lines
      return if lines.blank? || msg_handler.nil?
      msg_handler.msg( lines )
    rescue Exception => e
      Rails.logger.error "IngestContentService.call(#{path_to_yaml_file}) #{e.class}: #{e.message} at\n#{e.backtrace.join("\n")}"
    end

    def initialize( options:, msg_handler:, path_to_yaml_file:, cfg_hash:, base_path:, ingester:, mode:, first_label: )
      @msg_handler = msg_handler
      @first_label = first_label
      @mode = mode
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "options=#{options}",
                                             "path_to_yaml_file=#{path_to_yaml_file}",
                                             "cfg_hash=#{cfg_hash}",
                                             "base_path=#{base_path}",
                                             "ingester=#{ingester}",
                                             "mode=#{mode}",
                                             "first_label=#{first_label}",
                                             "" ] if ingest_content_service_debug_verbose
      initialize_with_msg( options: options,
                           path_to_yaml_file: path_to_yaml_file,
                           cfg_hash: cfg_hash,
                           base_path: base_path,
                           ingester: ingester,
                           mode: mode,
                           use_rails_logger: true,
                           msg: "NEW CONTENT SERVICE AT YOUR ... SERVICE" )
    end

    protected

      def build_repo_contents
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "Starting build_repo_contents...",
                                               "" ] if ingest_content_service_debug_verbose
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
                                               "" ] if ingest_content_service_debug_verbose
      end

  end

end

