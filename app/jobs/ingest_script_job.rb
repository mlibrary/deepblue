# frozen_string_literal: true

class IngestScriptJob < ::Hyrax::ApplicationJob

  mattr_accessor :ingest_script_job_debug_verbose,
                 default: ::Deepblue::IngestIntegrationService.ingest_script_job_debug_verbose

  include JobHelper # see JobHelper for :email_targets, :hostname, :job_msg_queue, :timestamp_begin, :timestamp_end
  queue_as ::Deepblue::IngestIntegrationService.ingest_append_queue_name

  attr_accessor :ingest_mode, :ingester, :path_to_script

  def perform( ingest_mode:, ingester:, path_to_script:, **options )
    timestamp_begin
    email_targets << ingester if ingester.present?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                           "ingest_mode=#{ingest_mode}",
                                           "ingester=#{ingester}",
                                           "path_to_script=#{path_to_script}",
                                           "options=#{options}",
                                           ::Deepblue::LoggingHelper.obj_class( 'options', options ),
                                           "" ] if ingest_script_job_debug_verbose

    @ingest_mode = ingest_mode
    @ingester = ingester
    @path_to_script = path_to_script
    ::Deepblue::IngestContentService.call( path_to_yaml_file: path_to_script,
                                           ingester: ingester,
                                           mode: ingest_mode,
                                           options: options )

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                           "ingest_mode=#{ingest_mode}",
                                           "ingester=#{ingester}",
                                           "path_to_script=#{path_to_script}",
                                           "options=#{options}",
                                           ::Deepblue::LoggingHelper.obj_class( 'options', options ),
                                           "" ] if ingest_script_job_debug_verbose

  rescue Exception => e # rubocop:disable Lint/RescueException
    Rails.logger.error "#{e.class} #{e.message} at #{e.backtrace[0]}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

end
