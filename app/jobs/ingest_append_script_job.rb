# frozen_string_literal: true

class IngestAppendScriptJob < ::Deepblue::DeepblueJob

  mattr_accessor :ingest_append_script_job_debug_verbose,
                 default: ::Deepblue::IngestIntegrationService.ingest_append_script_job_debug_verbose

  queue_as ::Deepblue::IngestIntegrationService.ingest_append_queue_name

  attr_accessor :ingest_mode, :ingester, :ingest_script_path

  EVENT = 'ingest append script'

  def perform( ingest_script_path:, ingester:, run_count: 0, **options )
    msg_handler.debug_verbose = ingest_append_script_job_debug_verbose
    initialize_with( debug_verbose: msg_handler.debug_verbose, options: options )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "ingest_script_path=#{ingest_script_path}",
                                           "ingester=#{ingester}",
                                           "run_count=#{run_count}",
                                           "options=#{options}",
                                           ::Deepblue::LoggingHelper.obj_class( 'options', options ),
                                           "" ] if ingest_append_script_job_debug_verbose

    @ingester = ingester
    @ingest_script_path = ingest_script_path
    ::Deepblue::IngestAppendContentService.call_append( msg_handler: msg_handler,
                                                        ingest_script_path: ingest_script_path,
                                                        ingester: ingester,
                                                        job_json: self.as_json,
                                                        run_count: run_count,
                                                        options: options )

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                           "ingest_script_path=#{ingest_script_path}",
                                           "ingester=#{ingester}",
                                           "options=#{options}",
                                           ::Deepblue::LoggingHelper.obj_class( 'options', options ),
                                           "" ] if ingest_append_script_job_debug_verbose
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e,
                         args: { ingest_script_path: ingest_script_path,
                                 ingester: ingester,
                                 run_count: run_count,
                                 options: options } )
    # email_failure( task_name: self.class.name, exception: e, event: self.class.name )
    raise e
  end

end
