# frozen_string_literal: true

class IngestScriptJob < ::Deepblue::DeepblueJob

  mattr_accessor :ingest_script_job_debug_verbose,
                 default: ::Deepblue::IngestIntegrationService.ingest_script_job_debug_verbose

  include JobHelper # see JobHelper for :by_request_only, :email_targets, :hostname, :job_msg_queue, :timestamp_begin, :timestamp_end
  queue_as ::Deepblue::IngestIntegrationService.ingest_append_queue_name

  attr_accessor :ingest_mode, :ingester, :path_to_script

  def perform( ingest_mode:, ingester:, path_to_script:, id: nil, **options )
    msg_handler.debug_verbose = ingest_script_job_debug_verbose
    initialize_with( debug_verbose: debug_verbose, options: options )
    job_status.main_cc_id = id if id.present?
    job_status.save! if id.present?
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
    ::Deepblue::IngestContentService.call( msg_handler: msg_handler,
                                           path_to_yaml_file: path_to_script,
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
    email_results( msg_handler: msg_handler, debug_verbose: debug_verbose )
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    msg_handler.msg_exception( e ) if msg_handler.present?
    job_status_register( exception: e,
                         args: { ingest_mode: ingest_mode,
                                 ingester: ingester,
                                 path_to_script: path_to_script,
                                 id: id,
                                 options: options } )
    email_failure( task_name: self.class.name, exception: e, event: self.class.name )
    Rails.logger.error "#{e.class} #{e.message} at #{e.backtrace[0]}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

end
