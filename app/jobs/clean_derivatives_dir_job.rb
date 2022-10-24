# frozen_string_literal: true

require_relative '../services/deepblue/clean_derivatives_dir_service'

class CleanDerivativesDirJob < AbstractRakeTaskJob

  mattr_accessor :clean_derivatives_dir_job_debug_verbose, default: false

  mattr_accessor :default_args, default: { by_request_only: false,
                                           from_dashboard: '',
                                           is_quiet: false,
                                           days_old: 7,
                                           task: false,
                                           to_console: false,
                                           verbose: false }

  SCHEDULER_ENTRY = <<-END_OF_SCHEDULER_ENTRY

clean_derivatives_dir_job:
  # Run once a week on Sundays at 4:05 PM (which is offset by 4 or [5 during daylight savings time], due to GMT)
  #      M  H     DoW
  cron: '5 21 * * 0'
  # rails_env: production
  class: CleanDerivativesDirJob
  queue: scheduler
  description: Clean the tmp/derivatives directory.
  args:
    days_old: 7
    email_results_to:
      - 'fritx@umich.edu'
    subscription_service_id: clean_derivatives_dir_job
    verbose: true

END_OF_SCHEDULER_ENTRY

  queue_as :scheduler

  def perform( *args )
    debug_verbose = clean_derivatives_dir_job_debug_verbose
    initialized = initialize_from_args( *args, debug_verbose: debug_verbose )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "initialized=#{initialized}",
                                           "" ] if debug_verbose
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name, event: event_name )
    return unless initialized
    days_old = job_options_value( key: 'days_old', default_value: default_args[:days_old] )
    ::Deepblue::CleanDerivativesDirService.new( days_old: days_old, msg_handler: msg_handler ).run
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
