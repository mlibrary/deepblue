# frozen_string_literal: true

require_relative '../services/server_logs_copy_service'

class CopyLogsDirJob < AbstractRakeTaskJob

  mattr_accessor :copy_logs_job_debug_verbose, default: false

  mattr_accessor :default_args, default: { by_request_only: true,
                                           from_dashboard: '',
                                           is_quiet: false,
                                           task: false,
                                           to_console: false,
                                           verbose: false }

  SCHEDULER_ENTRY = <<-END_OF_SCHEDULER_ENTRY

copy_logs_job:
  # Run once a week on Sundays at 4:05 PM (which is offset by 4 or [5 during daylight savings time], due to GMT)
  #      M  H     DoW
  cron: '5 21 * * 0'
  # rails_env: production
  class: CopyLogsDirJob
  queue: scheduler
  description: Copy the contents of the log directory to deepblue-prep logs.
  args:
    by_request_only: true
    email_results_to:
      - 'fritx@umich.edu'
    subscription_service_id: copy_logs_job
    verbose: true

END_OF_SCHEDULER_ENTRY

  queue_as :scheduler

  def perform( *args )
    debug_verbose = copy_logs_job_debug_verbose
    initialized = initialize_from_args( *args, debug_verbose: debug_verbose )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "initialized=#{initialized}",
                                           "" ] if debug_verbose
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name, event: event_name )
    return unless initialized
    # days_old = job_options_value( key: 'days_old', default_value: default_args[:days_old] )
    # filter: nil, root_dir: "./log", target_root_dir: "/deepbluedata-preplogs/", msg_handler:, verbose:
    ::ServerLogsCopyService.new( filter: nil, msg_handler: msg_handler, verbose: verbose ).run
    timestamp_end = DateTime.now
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "msg_handler.msg_queue=#{msg_handler.msg_queue}",
                                           "timestamp_end=#{timestamp_end}",
                                           "" ] if debug_verbose
    email_results( task_name: task_name, event: event_name )
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: args, rails_log: true )
    email_failure( task_name: task_name, exception: e, event: event_name )
    raise e
  end

end
