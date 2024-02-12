# frozen_string_literal: true

require "abstract_rake_task_job"

class AptrustVerifyWorkJob < AbstractRakeTaskJob

  # bundle exec rake deepblue:run_job['{"job_class":"AptrustVerifyWorkJob"\,"debug_verbose":"gf06g2796"\,"verbose":true\,"email_results_to":["fritx@umich.edu"]\,"job_delay":0\,"force_verification":true\,"reverify_failed":true\,"debug_verbose":true}']

  mattr_accessor :aptrust_verify_work_job_debug_verbose, default: false

  queue_as :aptrust

  SCHEDULER_ENTRY = <<-END_OF_SCHEDULER_ENTRY

aptrust_verify_work_job:
# Run once a day, 15 minutes after midnight (which is offset by 4 or [5 during daylight savings time], due to GMT)
#       M H D
  cron: '15 5 * * *'
  class: AptrustVerifyWorkJob
  queue: aptrust
  description: Verify a work uploaded to APTrust
  args:
    by_request_only: true
    #debug_assume_verify_succeeds: true
    #debug_verbose: true
    force_verification: false
    id: xyz
    reverify_failed: false
    email_results_to:
      - 'fritx@umich.edu'
    hostnames:
      - 'deepblue.lib.umich.edu'
      - 'staging.deepblue.lib.umich.edu'
      - 'testing.deepblue.lib.umich.edu'
    subscription_service_id: aptrust_verify_work_job
    verbose: false

  END_OF_SCHEDULER_ENTRY

  EVENT = "aptrust_verify_work"

  def self.perform( *args )
    AptrustVerifyWorkJob.perform_now( *args )
  end

  def perform( *args )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "args=#{args}",
                                           "" ] if aptrust_verify_work_job_debug_verbose
    initialized = initialize_from_args( *args, debug_verbose: aptrust_verify_work_job_debug_verbose )
    msg_handler.bold_debug [ msg_handler.here,
                             msg_handler.called_from,
                             "initialized=#{initialized}",
                             "" ] if debug_verbose
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name )
    return unless initialized
    begin # until true for break
      debug_verbose = job_options_value( key: 'debug_verbose', default_value: debug_verbose )
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "by_request_only?=#{by_request_only?}",
                               "allow_by_request_only?=#{allow_by_request_only?}",
                               "" ] if debug_verbose
      break if by_request_only? && !allow_by_request_only?
      msg_handler.debug_verbose = debug_verbose
      debug_assume_verify_succeeds = job_options_value( key: 'debug_assume_verify_succeeds', default_value: false )
      force_verification = job_options_value( key: 'force_verification', default_value: false )
      reverify_failed = job_options_value( key: 'reverify_failed', default_value: false )
      msg_handler.bold_debug [ msg_handler.here,
                             msg_handler.called_from,
                             "debug_assume_verify_succeeds=#{debug_assume_verify_succeeds}",
                             "force_verification=#{force_verification}",
                             "reverify_failed=#{reverify_failed}",
                             "" ] if debug_verbose
      run_job_delay
      id = job_options_value( key: 'id', default_value: nil )
      verifier = ::Aptrust::AptrustVerifyWork.new( debug_assume_verify_succeeds: debug_assume_verify_succeeds,
                                                   force_verification:           force_verification,
                                                   reverify_failed:              reverify_failed,
                                                   noid:                         id,
                                                   msg_handler:                  msg_handler,
                                                   debug_verbose:                debug_verbose )
      verifier.run
      timestamp_end = DateTime.now
      msg_handler.bold_debug [ msg_handler.here,
                             msg_handler.called_from,
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
