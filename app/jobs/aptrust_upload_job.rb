# frozen_string_literal: true

require "abstract_rake_task_job"

class AptrustUploadJob < AbstractRakeTaskJob

  # bundle exec rake deepblue:run_job['{"job_class":"AptrustUploadJob"\,"verbose":true\,"email_results_to":["fritx@umich.edu"]\,"job_delay":0}']

  mattr_accessor :aptrust_upload_job_debug_verbose, default: false

  queue_as :aptrust

  SCHEDULER_ENTRY = <<-END_OF_SCHEDULER_ENTRY

aptrust_upload_job:
# Run once a day, 15 minutes after midnight (which is offset by 4 or [5 during daylight savings time], due to GMT)
#       M H D
  cron: '15 5 * * *'
  class: AptrustUploadJob
  queue: aptrust
  description: Scan and upload works to APTrust
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
    #filter_debug_verbose: true
    email_results_to:
      - 'fritx@umich.edu'
    #filter_date_begin: now - 7 days
    #filter_date_end: now
    #filter_min_total_size: 1
    #filter_max_total_size: 1000000 # 1 million bytes
    #filter_max_total_size: 1000000000 # 1 billion bytes
    #filter_ignore_status: true # i.e. reupload
    xfilter_skip_statuses: # see: ::Aptrust::FilterStatus::SKIP_STATUSES
      - uploaded
      - verified
      - deposited
      - deposit_skipped
      - upload_skipped
      - export_failed
      - verified
      - verify_failed
      - verifying
    hostnames:
      - 'deepblue.lib.umich.edu'
      - 'staging.deepblue.lib.umich.edu'
      - 'testing.deepblue.lib.umich.edu'
    #max_upload_jobs: 1
    #max_uploads: 3
    subscription_service_id: aptrust_upload_job
    verbose: false

  END_OF_SCHEDULER_ENTRY

  EVENT = "aptrust_upload"

  def self.perform( *args )
    RakeTaskJob.perform_now( *args )
  end

  def perform( *args )
    # msg_handler.debug_verbose = aptrust_upload_job_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
                                           "args=#{args}",
                                           "" ] if aptrust_upload_job_debug_verbose
    initialized = initialize_from_args( *args, debug_verbose: aptrust_upload_job_debug_verbose )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "initialized=#{initialized}",
                             "" ] if aptrust_upload_job_debug_verbose
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name )
    return unless initialized
    begin # until true for break
      debug_verbose = job_options_value( key: 'debug_verbose', default_value: debug_verbose )
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "by_request_only?=#{by_request_only?}",
                               "allow_by_request_only?=#{allow_by_request_only?}",
                               "" ] if debug_verbose
      break if by_request_only? && !allow_by_request_only?
      msg_handler.debug_verbose = debug_verbose
      debug_assume_upload_succeeds  = job_options_value( key: 'debug_assume_upload_succeeds', default_value: false )
      clean_up_after_deposit        = job_options_value( key: 'clean_up_after_deposit', default_value: true )
      clean_up_bag                  = job_options_value( key: 'clean_up_bag', default_value: false )
      clean_up_bag_data             = job_options_value( key: 'clean_up_bag_data', default_value: true )
      clear_status                  = job_options_value( key: 'clear_status', default_value: true )
      export_file_sets              = job_options_value( key: 'export_file_sets', default_value: true )
      export_file_sets_filter_date  = job_options_value( key: 'export_file_sets_filter_date', default_value: true )
      export_file_sets_filter_event = job_options_value( key: 'export_file_sets_filter_event', default_value: true )
      filter_debug_verbose          = job_options_value( key: 'filter_debug_verbose', default_value: false )
      filter_ignore_status          = job_options_value( key: 'filter_ignore_status', default_value: false )
      filter_date_begin             = job_options_value( key: 'filter_date_begin', default_value: nil )
      filter_date_end               = job_options_value( key: 'filter_date_end', default_value: nil )
      filter_min_total_size         = job_options_value( key: 'filter_min_total_size', default_value: 1 )
      filter_max_total_size         = job_options_value( key: 'filter_max_total_size', default_value: nil )
      filter_skip_statuses          = job_options_value( key: 'filter_skip_statuses', default_value: [] )
      max_upload_jobs               = job_options_value( key: 'max_upload_jobs', default_value: 1 )
      max_uploads                   = job_options_value( key: 'max_uploads', default_value: -1 )
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "debug_assume_upload_succeeds=#{debug_assume_upload_succeeds}",
                               "clean_up_after_deposit=#{clean_up_after_deposit}",
                               "clean_up_bag=#{clean_up_bag}",
                               "clean_up_bag_data=#{clean_up_bag_data}",
                               "clear_status=#{clear_status}",
                               "export_file_sets=#{export_file_sets}",
                               "export_file_sets_filter_date=#{export_file_sets_filter_date}",
                               "export_file_sets=#{export_file_sets}",
                               "filter_ignore_status=#{filter_ignore_status}",
                               "filter_date_begin=#{filter_date_begin}",
                               "filter_date_end=#{filter_date_end}",
                               "filter_min_total_size=#{filter_min_total_size}",
                               "filter_max_total_size=#{filter_max_total_size}",
                               "filter_skip_statuses=#{filter_skip_statuses}",
                               "max_upload_jobs=#{max_upload_jobs}",
                               "max_uploads=#{max_uploads}",
                               "" ] if debug_verbose
      run_job_delay
      filter = ::Aptrust::AptrustFilterWork.new
      filter.set_filter_by_date( begin_date: filter_date_begin, end_date: filter_date_end )
      filter.set_filter_by_size( min_size: filter_min_total_size, max_size: filter_max_total_size )
      if filter_ignore_status
        filter.set_filter_by_status( skip_statuses: nil )
      else
        filter.set_filter_by_status( skip_statuses: filter_skip_statuses )
      end
      filter.debug_verbose = filter_debug_verbose
      run_job_delay
      finder = ::Aptrust::AptrustFindAndUpload.new( clean_up_after_deposit:        clean_up_after_deposit,
                                                    clean_up_bag:                  clean_up_bag,
                                                    clean_up_bag_data:             clean_up_bag_data,
                                                    clear_status:                  clear_status,
                                                    debug_assume_upload_succeeds:  debug_assume_upload_succeeds,
                                                    export_file_sets:              export_file_sets,
                                                    export_file_sets_filter_date:  export_file_sets_filter_date,
                                                    export_file_sets_filter_event: export_file_sets_filter_event,
                                                    filter:                        filter,
                                                    max_upload_jobs:               max_upload_jobs,
                                                    max_uploads:                   max_uploads,
                                                    msg_handler:                   msg_handler,
                                                    debug_verbose:                 debug_verbose )
      finder.run
      timestamp_end = DateTime.now
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "msg_handler.msg_queue=#{msg_handler.msg_queue}",
                             "timestamp_end=#{timestamp_end}",
                             "" ] if aptrust_upload_job_debug_verbose
      email_results( task_name: EVENT, event: EVENT )
    end until true # for break
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: args )
    email_failure( task_name: EVENT, exception: e, event: EVENT )
    raise e
  end

end
