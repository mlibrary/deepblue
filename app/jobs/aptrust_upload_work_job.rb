# frozen_string_literal: true

require "abstract_rake_task_job"

class AptrustUploadWorkJob < AbstractRakeTaskJob

  # bundle exec rake deepblue:run_job['{"job_class":"AptrustVerifyWorkJob"\,"id":"gf06g2796"\,"verbose":true\,"email_results_to":["fritx@umich.edu"]\,"job_delay":0\,"force_verification":true\,"reverify_failed":true\,"debug_verbose":true}']

  mattr_accessor :aptrust_upload_work_job_debug_verbose, default: false

  queue_as :aptrust

  SCHEDULER_ENTRY = <<-END_OF_SCHEDULER_ENTRY

aptrust_upload_work_job:
# Run once a day, 15 minutes after midnight (which is offset by 4 or [5 during daylight savings time], due to GMT)
#       M H D
  cron: '15 5 * * *'
  class: AptrustUploadWorkJob
  queue: aptrust
  description: Upload a work to APTrust
  args:
    by_request_only: true
    clean_up_after_deposit: true
    clean_up_bag: false
    clean_up_bag_data: true
    clear_status: true
    export_file_sets: true
    export_file_sets_filter_date: ''
    export_file_sets_filter_event: ''
    #debug_assume_upload_succeeds: true
    #debug_verbose: true
    id: xyz
    email_results_to:
      - 'fritx@umich.edu'
    hostnames:
      - 'deepblue.lib.umich.edu'
      - 'staging.deepblue.lib.umich.edu'
      - 'testing.deepblue.lib.umich.edu'
    subscription_service_id: aptrust_upload_work_job
    verbose: false

  END_OF_SCHEDULER_ENTRY

  EVENT = "aptrust_upload_work"

  def self.perform( *args )
    AptrustUploadWorkJob.perform_now( *args )
  end

  def perform( *args )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "args=#{args}",
                                           "" ] if aptrust_upload_work_job_debug_verbose
    initialized = initialize_from_args( *args, debug_verbose: aptrust_upload_work_job_debug_verbose )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "initialized=#{initialized}",
                             "" ] if aptrust_upload_work_job_debug_verbose
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name )
    return unless initialized
    begin # until true for break
      debug_verbose = job_options_value( key: 'debug_verbose', default_value: debug_verbose )
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "by_request_only?=#{by_request_only?}",
                               "allow_by_request_only?=#{allow_by_request_only?}",
                               "" ] if debug_verbose
      break if by_request_only? && !allow_by_request_only?
      msg_handler.debug_verbose     = debug_verbose
      debug_assume_upload_succeeds  = job_options_value( key: 'debug_assume_upload_succeeds',  default_value: false )
      clean_up_after_deposit        = job_options_value( key: 'clean_up_after_deposit',        default_value: true )
      clean_up_bag                  = job_options_value( key: 'clean_up_bag',                  default_value: false )
      clean_up_bag_data             = job_options_value( key: 'clean_up_bag_data',             default_value: true )
      clear_status                  = job_options_value( key: 'clear_status',                  default_value: true )
      export_file_sets              = job_options_value( key: 'export_file_sets',              default_value: nil )
      export_file_sets_filter_date  = job_options_value( key: 'export_file_sets_filter_date',  default_value: nil )
      export_file_sets_filter_event = job_options_value( key: 'export_file_sets_filter_event', default_value: nil )
      id                            = job_options_value( key: 'id',                            default_value: nil )
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "debug_assume_upload_succeeds=#{debug_assume_upload_succeeds}",
                               "clean_up_after_deposit=#{clean_up_after_deposit}",
                               "clean_up_bag=#{clean_up_bag}",
                               "clean_up_bag_data=#{clean_up_bag_data}",
                               "clear_status=#{clear_status}",
                               "export_file_sets=#{export_file_sets}",
                               "export_file_sets_filter_date=#{export_file_sets_filter_date}",
                               "export_file_sets_filter_event=#{export_file_sets_filter_event}",
                               "id=#{id}",
                               "" ] if debug_verbose
      run_job_delay
      uploader = ::Aptrust::AptrustUploadWork.new( clean_up_after_deposit:        clean_up_after_deposit,
                                                   clean_up_bag:                  clean_up_bag,
                                                   clean_up_bag_data:             clean_up_bag_data,
                                                   clear_status:                  clear_status,
                                                   debug_assume_upload_succeeds:  debug_assume_upload_succeeds,
                                                   export_file_sets:              export_file_sets,
                                                   export_file_sets_filter_date:  export_file_sets_filter_date,
                                                   export_file_sets_filter_event: export_file_sets_filter_event,
                                                   noid:                          id,
                                                   msg_handler:                   msg_handler,
                                                   debug_verbose:                 debug_verbose )
      uploader.run
      timestamp_end = DateTime.now
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "msg_handler.msg_queue=#{msg_handler.msg_queue}",
                             "timestamp_end=#{timestamp_end}",
                             "" ] if debug_verbose
      email_results( task_name: EVENT, event: EVENT )
    end until true # for break
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: args )
    email_failure( task_name: EVENT, exception: e, event: EVENT )
    raise e
  end

end
