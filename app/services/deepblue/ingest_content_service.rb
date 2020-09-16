# frozen_string_literal: true

module Deepblue

  require_relative '../../../lib/tasks/new_content_service'

  # Given a configuration hash read from a yaml file, build the contents in the repository.
  class IngestContentService < NewContentService

    INGEST_CONTENT_SERVICE_DEBUG_VERBOSE = fasle

    def self.call( path_to_yaml_file:, ingester: nil, mode: nil, first_label: 'work_id', options: )
      cfg_hash = Deepblue::NewContentService.load_yaml_file( path_to_yaml_file )
      return false if cfg_hash.nil? || cfg_hash.empty?
      base_path = File.dirname( path_to_yaml_file )
      bcs = IngestContentService.new( options: options,
                                      path_to_yaml_file: path_to_yaml_file,
                                      cfg_hash: cfg_hash,
                                      ingester: ingester,
                                      first_label: first_label,
                                      mode: mode,
                                      base_path: base_path )
      bcs.run
    rescue Exception => e
      Rails.logger.error "IngestContentService.call(#{path_to_yaml_file}) #{e.class}: #{e.message} at\n#{e.backtrace.join("\n")}"
    end

    def initialize( options:, path_to_yaml_file:, cfg_hash:, base_path:, ingester:, mode:, first_label: )
      @first_label = first_label
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "options=#{options}",
                                             "path_to_yaml_file=#{path_to_yaml_file}",
                                             "base_path=#{base_path}",
                                             "cfg_hash=#{cfg_hash}",
                                             "ingester=#{ingester}",
                                             "mode=#{mode}",
                                             "first_label=#{first_label}",
                                             "" ] if INGEST_CONTENT_SERVICE_DEBUG_VERBOSE
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
        ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                               Deepblue::LoggingHelper.called_from,
                                               Deepblue::LoggingHelper.obj_class( 'class', self ),
                                               "Starting build_repo_contents...",
                                               "" ] if INGEST_CONTENT_SERVICE_DEBUG_VERBOSE
        do_email_before
        # user = find_or_create_user
        find_works_and_add_files
        # build_collections
        report_measurements( first_label: @first_label )
        do_email_after
        ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                               Deepblue::LoggingHelper.called_from,
                                               Deepblue::LoggingHelper.obj_class( 'class', self ),
                                               "Finished build_repo_contents.",
                                               "" ] if INGEST_CONTENT_SERVICE_DEBUG_VERBOSE
      end

  end

end

