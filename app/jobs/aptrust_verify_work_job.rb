# frozen_string_literal: true

require "abstract_rake_task_job"

class AptrustVerifyWorkJob < AbstractRakeTaskJob

  # bundle exec rake deepblue:run_job['{"job_class":"AptrustVerifyWorkJob"\,"verbose":true\,"email_results_to":["fritx@umich.edu"]\,"job_delay":0}']

  mattr_accessor :aptrust_verify_work_job_debug_verbose, default: false

  EVENT = "aptrust_upload_work"

  def self.perform( *args )
    AptrustVerifyWorkJob.perform_now( *args )
  end

  def perform( *args )
    # msg_handler.debug_verbose = aptrust_upload_work_job_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "args=#{args}",
                                           "" ] if aptrust_verify_work_job_debug_verbose
    initialized = initialize_from_args( *args, debug_verbose: debug_verbose )
    msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                             ::Deepblue::LoggingHelper.called_from,
                             "initialized=#{initialized}",
                             "" ] if aptrust_verify_work_job_debug_verbose
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name )
    return unless initialized
    # export_dir = job_options_value( key: 'export_dir', default_value: nil )
    run_job_delay
    id = job_options_value( key: 'id', default_value: nil )
    # work = DataSet.find id
    service = ::Aptrust::AptrustStatusService.new( msg_handler: msg_handler )
    status = service.ingest_status( identifier: id )
    # TODO: do something with status
    timestamp_end = DateTime.now
    # email_results( task_name: EVENT, event: EVENT )
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: args )
    email_failure( task_name: EVENT, exception: e, event: EVENT )
    raise e
  end

end
