# frozen_string_literal: true

require "abstract_rake_task_job"

class AptrustUploadJob < AbstractRakeTaskJob

  # bundle exec rake deepblue:run_job['{"job_class":"AptrustUploadJob"\,"verbose":true\,"email_results_to":["fritx@umich.edu"]\,"job_delay":0}']

  mattr_accessor :aptrust_upload_job_debug_verbose, default: false

  # queue_as :scheduler

  SCHEDULER_ENTRY = <<-END_OF_SCHEDULER_ENTRY

aptrust_upload_job:
# Run once a day, 15 minutes after midnight (which is offset by 4 or [5 during daylight savings time], due to GMT)
#       M H D
  cron: '15 5 * * *'
  class: AptrustUploadJob
  queue: scheduler
  description: Scan and upload works to APTrust
  args:
    email_results_to:
      - 'fritx@umich.edu'
    xfilter_date_begin: now - 7 days
    xfilter_date_end: now
    filter_min_total_size: 
    filter_max_total_size: 
    filter_skip_statuses:
      - uploaded
      - verified
    hostnames:
      - 'deepblue.lib.umich.edu'
      - 'staging.deepblue.lib.umich.edu'
      - 'testing.deepblue.lib.umich.edu'
    subscription_service_id: aptrust_upload_job
    verbose: false

  END_OF_SCHEDULER_ENTRY

  EVENT = "aptrust_upload"

  def self.perform( *args )
    RakeTaskJob.perform_now( *args )
  end

  def perform( *args )
    # msg_handler.debug_verbose = aptrust_upload_job_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "args=#{args}",
                                           "" ] if aptrust_upload_job_debug_verbose
    initialized = initialize_from_args( *args, debug_verbose: debug_verbose )
    msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                             ::Deepblue::LoggingHelper.called_from,
                             "initialized=#{initialized}",
                             "" ] if aptrust_upload_job_debug_verbose
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name )
    return unless initialized
    filter_date_begin = job_options_value( key: 'filter_date_begin', default_value: nil )
    filter_date_end = job_options_value( key: 'filter_date_end', default_value: nil )
    filter_min_total_size = job_options_value( key: 'filter_min_total_size', default_value: 1 )
    filter_max_total_size = job_options_value( key: 'filter_max_total_size', default_value: nil )
    filter_skip_statuses = job_options_value( key: 'filter_skip_statuses', default_value: [] )
    msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                             ::Deepblue::LoggingHelper.called_from,
                             "filter_date_begin=#{filter_date_begin}",
                             "filter_date_end=#{filter_date_end}",
                             "filter_min_total_size=#{filter_min_total_size}",
                             "filter_max_total_size=#{filter_max_total_size}",
                             "filter_skip_statuses=#{filter_skip_statuses}",
                             "" ] if aptrust_upload_job_debug_verbose
    run_job_delay
    filter = ::Aptrust::AptrustFilterWork.new
    filter.set_filter_by_date( begin_date: filter_date_begin, end_date: filter_date_end )
    filter.set_filter_by_size( min_size: filter_min_total_size, max_size: filter_max_total_size )
    filter.set_filter_by_status( skip_statuses: filter_skip_statuses )
    finder = ::Aptrust::AptrustFindAndUpload.new( filter: filter, msg_handler: msg_handler )
    finder.run
    timestamp_end = DateTime.now
    msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                             ::Deepblue::LoggingHelper.called_from,
                             "msg_handler.msg_queue=#{msg_handler.msg_queue}",
                             "timestamp_end=#{timestamp_end}",
                             "" ] if aptrust_upload_job_debug_verbose
    email_results( task_name: EVENT, event: EVENT )
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: args )
    email_failure( task_name: EVENT, exception: e, event: EVENT )
    raise e
  end

end
