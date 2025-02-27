# frozen_string_literal: true

class IngestAppendScriptJob < ::Deepblue::DeepblueJob

  mattr_accessor :ingest_append_script_job_debug_verbose,
                 default: ::Deepblue::IngestIntegrationService.ingest_append_script_job_debug_verbose

  mattr_accessor :ingest_append_script_job_verbose,
                 default: ::Deepblue::IngestIntegrationService.ingest_append_script_job_verbose

  queue_as ::Deepblue::IngestIntegrationService.ingest_append_queue_name

  attr_accessor :ingest_mode
  attr_accessor :ingester
  attr_accessor :ingest_script_path
  attr_accessor :run_count

  EVENT = 'ingest append script'

  #def perform( id:, ingest_script_path:, ingester:, max_appends:, restart:, run_count:, **options )
  def perform( *args )
    args = [{}] if args.nil? || args[0].nil?
    id = args[0][:id]
    ingest_script_path = args[0][:ingest_script_path]
    ingester = args[0][:ingester]
    max_appends = args[0][:max_appends]
    restart = args[0][:restart]
    run_count = args[0][:run_count]
    options = args[0][:options]
    options ||= {}
    msg_handler.debug_verbose = msg_handler.debug_verbose || ingest_append_script_job_debug_verbose
    msg_handler.verbose = msg_handler.verbose || ingest_append_script_job_verbose
    msg_handler.msg_verbose msg_handler.here
    msg_handler.msg_verbose "id=#{id}"
    msg_handler.msg_verbose "ingest_script_path=#{ingest_script_path}"
    msg_handler.msg_verbose "ingester=#{ingester}"
    msg_handler.msg_verbose "max_appends=#{max_appends}"
    msg_handler.msg_verbose "run_count=#{run_count}"
    initialize_with( debug_verbose: msg_handler.debug_verbose, options: options )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "id=#{id}",
                                           "ingest_script_path=#{ingest_script_path}",
                                           "ingester=#{ingester}",
                                           "max_appends=#{max_appends}",
                                           "run_count=#{run_count}",
                                           "options=#{options}",
                                           ::Deepblue::LoggingHelper.obj_class( 'options', options ),
                                           "" ] if ingest_append_script_job_debug_verbose
    @run_count = run_count
    @ingester = ingester
    @ingest_script_path = ingest_script_path
    ::Deepblue::IngestAppendContentService.call_append( msg_handler: msg_handler,
                                                        ingest_script_path: ingest_script_path,
                                                        ingester: ingester,
                                                        job_json: self.as_json,
                                                        max_appends: max_appends,
                                                        restart: restart,
                                                        run_count: run_count,
                                                        options: options )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "ingest_script_path=#{ingest_script_path}",
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
