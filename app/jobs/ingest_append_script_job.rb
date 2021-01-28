# frozen_string_literal: true

class IngestAppendScriptJob < ::Hyrax::ApplicationJob

  mattr_accessor :ingest_append_script_job_debug_verbose
  @@ingest_append_script_job_debug_verbose = false

  include JobHelper
  queue_as ::Deepblue::IngestIntegrationService.ingest_append_queue_name

  def perform( path_to_script:, ingester:, **options )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                           "path_to_script=#{path_to_script}",
                                           "ingester=#{ingester}",
                                           "options=#{options}",
                                           ::Deepblue::LoggingHelper.obj_class( 'options', options ),
                                           "" ] if ingest_append_script_job_debug_verbose
    # verbose = job_options_value(options, key: 'verbose', default_value: false )
    # ::Deepblue::LoggingHelper.debug "verbose=#{verbose}" if verbose
    # hostnames = job_options_value(options, key: 'hostnames', default_value: [], verbose: verbose )
    # hostname = ::DeepBlueDocs::Application.config.hostname
    # return unless hostnames.include? hostname

    ::Deepblue::IngestContentService.call( path_to_yaml_file: path_to_script,
                                                ingester: ingester,
                                                mode: 'append',
                                                options: options )

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                           "path_to_script=#{path_to_script}",
                                           "ingester=#{ingester}",
                                           "options=#{options}",
                                           ::Deepblue::LoggingHelper.obj_class( 'options', options ),
                                           "" ] if ingest_append_script_job_debug_verbose

  rescue Exception => e # rubocop:disable Lint/RescueException
    Rails.logger.error "#{e.class} #{e.message} at #{e.backtrace[0]}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

end
