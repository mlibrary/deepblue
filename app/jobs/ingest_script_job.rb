# frozen_string_literal: true

class IngestScriptJob < ::Deepblue::DeepblueJob

  mattr_accessor :ingest_script_job_debug_verbose,
                 default: ::Deepblue::IngestIntegrationService.ingest_script_job_debug_verbose

  queue_as ::Deepblue::IngestIntegrationService.ingest_append_queue_name

  attr_accessor :ingest_mode, :ingester, :path_to_script

  EVENT = 'ingest script'

  # job_delay in seconds
  # def perform( ingest_mode:, ingester:, path_to_script:, id: nil, **options )
  # hyrax4 / ruby3 upgrade
  def perform( *args )
    args = [{}] if args.nil? || args[0].nil?
    ingest_mode = args[0][:ingest_mode]
    ingester = args[0][:ingester]
    path_to_script = args[0][:path_to_script]
    id = args[0][:id]
    options = args[0][:options]
    options ||= {}
    # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
    #                                         "ingest_mode=#{ingest_mode}",
    #                                         "ingester=#{ingester}",
    #                                         "id=#{id}",
    #                                         "path_to_script=#{path_to_script}",
    #                                         "options=#{options}",
    #                                        ::Deepblue::LoggingHelper.obj_class( 'options', options ),
    #                                         "" ] if ingest_script_job_debug_verbose
    msg_handler.debug_verbose = ingest_script_job_debug_verbose
    initialize_with( id: id, debug_verbose: debug_verbose, options: options )
    child_job?
    email_targets << ingester if ingester.present?
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "id=#{id}",
                             "ingest_mode=#{ingest_mode}",
                             "ingester=#{ingester}",
                             "path_to_script=#{path_to_script}",
                             "options=#{options}",
                             msg_handler.obj_class( 'options', options ),
                             "" ] if msg_handler.debug_verbose

    @ingest_mode = ingest_mode
    @ingester = ingester
    @path_to_script = path_to_script
    ::Deepblue::IngestContentService.call( msg_handler: msg_handler,
                                           path_to_yaml_file: path_to_script,
                                           ingester: ingester,
                                           mode: ingest_mode,
                                           options: options )

    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                                           "ingest_mode=#{ingest_mode}",
                                           "ingester=#{ingester}",
                                           "path_to_script=#{path_to_script}",
                                           "options=#{options}",
                                           msg_handler.obj_class( 'options', options ),
                                           "" ] if msg_handler.debug_verbose
    email_results( task_name: EVENT, event: EVENT )
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e,
                         args: { ingest_mode: ingest_mode,
                                 ingester: ingester,
                                 path_to_script: path_to_script,
                                 id: id,
                                 options: options } )
    email_failure( task_name: self.class.name, exception: e, event: self.class.name )
    raise e
  end

end
