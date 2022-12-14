# frozen_string_literal: true

class IngestAppendScriptJob < ::Deepblue::DeepblueJob

  mattr_accessor :ingest_append_script_job_debug_verbose,
                 default: ::Deepblue::IngestIntegrationService.ingest_append_script_job_debug_verbose

  queue_as ::Deepblue::IngestIntegrationService.ingest_append_queue_name

  attr_accessor :ingest_mode, :ingester, :path_to_script

  EVENT = 'ingest script'

  def perform( ingest_mode: 'append', ingester:, path_to_script:, id: nil, **options )
    msg_handler.debug_verbose = ingest_append_script_job_debug_verbose
    initialize_with( id: id, debug_verbose: debug_verbose, options: options )
    email_targets << ingester if ingester.present?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "id=#{id}",
                                           "ingest_mode=#{ingest_mode}",
                                           "ingester=#{ingester}",
                                           "path_to_script=#{path_to_script}",
                                           "options=#{options}",
                                           ::Deepblue::LoggingHelper.obj_class( 'options', options ),
                                           "" ] if ingest_append_script_job_debug_verbose

    @ingest_mode = ingest_mode
    @ingester = ingester
    @path_to_script = path_to_script
    ::Deepblue::IngestAppendContentService.call( curation_concern_id: id,
                                                 msg_handler: msg_handler,
                                                 path_to_yaml_file: path_to_script,
                                                 ingester: ingester,
                                                 mode: ingest_mode,
                                                 job_json: self.as_json,
                                                 options: options )

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                           "ingest_mode=#{ingest_mode}",
                                           "ingester=#{ingester}",
                                           "path_to_script=#{path_to_script}",
                                           "options=#{options}",
                                           ::Deepblue::LoggingHelper.obj_class( 'options', options ),
                                           "" ] if ingest_append_script_job_debug_verbose
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
