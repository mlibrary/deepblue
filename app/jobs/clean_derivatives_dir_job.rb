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

  include JobHelper # see JobHelper for :by_request_only, :email_targets, :hostname, :job_msg_queue, :timestamp_begin, :timestamp_end
  queue_as :scheduler

  def perform( *args )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "args=#{args}",
                                           ::Deepblue::LoggingHelper.obj_class( 'args', args ),
                                           "" ] if clean_derivatives_dir_job_debug_verbose
    initialized = initialize_from_args *args
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "initialized=#{initialized}",
                                           "" ] if clean_derivatives_dir_job_debug_verbose
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name, event: event_name )
    return unless initialized
    days_old = options_value( key: 'days_old', default_value: default_args[:days_old] )
    ::Deepblue::CleanDerivativesDirService.new( days_old: days_old,
                                                job_msg_queue: job_msg_queue,
                                                to_console: false,
                                                verbose: verbose ).run
    timestamp_end = DateTime.now
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "job_msg_queue=#{job_msg_queue}",
                                           "timestamp_end=#{timestamp_end}",
                                           "" ] if clean_derivatives_dir_job_debug_verbose
    email_results( task_name: task_name, event: event_name )
  rescue Exception => e # rubocop:disable Lint/RescueException
    Rails.logger.error "#{e.class} #{e.message} at #{e.backtrace[0]}"
    Rails.logger.error e.backtrace[0..20].join("\n")
    email_failure( task_name: task_name, exception: e, event: event_name )
    raise e
  end

end
