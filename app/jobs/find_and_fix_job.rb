# frozen_string_literal: true

require "abstract_rake_task_job"
# require "find_and_fix_service"

class FindAndFixJob < AbstractRakeTaskJob

  # bundle exec rake deepblue:run_job['{"job_class":"FindAndFixJob"\,"verbose":true\,"email_results_to":["fritx@umich.edu"]\,"job_delay":0}']

  mattr_accessor :find_and_fix_job_debug_verbose,
                 default: ::Deepblue::FindAndFixService.find_and_fix_job_debug_verbose

  # queue_as :scheduler

SCHEDULER_ENTRY = <<-END_OF_SCHEDULER_ENTRY

find_and_fix_job:
# Run once a day, 15 minutes after midnight (which is offset by 4 or [5 during daylight savings time], due to GMT)
#       M H D
  cron: '15 5 * * *'
  class: FindAndFixJob
  queue: scheduler
  description: Find and fix problems
  args:
    email_results_to:
      - 'fritx@umich.edu'
    filter_date_begin: now - 7 days
    filter_date_end: now
    hostnames:
      - 'deepblue.lib.umich.edu'
      - 'staging.deepblue.lib.umich.edu'
      - 'testing.deepblue.lib.umich.edu'
    subscription_service_id: find_and_fix_job
    verbose: false

END_OF_SCHEDULER_ENTRY

  def self.perform( *args )
    RakeTaskJob.perform_now( *args )
  end

  def perform( *args )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "args=#{args}",
                                           "" ] if find_and_fix_job_debug_verbose
    initialized = initialize_from_args *args
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "initialized=#{initialized}",
                                           "" ], bold_puts: task if find_and_fix_job_debug_verbose
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name )
    return unless initialized
    filter_date_begin = job_options_value( options,
                                           key: 'filter_date_begin',
                                           default_value: nil,
                                           verbose: verbose,
                                           task: task )
    filter_date_end = job_options_value( options,
                                         key: 'filter_date_end',
                                         default_value: nil,
                                         verbose: verbose,
                                         task: task )
    run_job_delay
    ::Deepblue::FindAndFixService.find_and_fix( filter_date_begin: filter_date_begin,
                                                filter_date_end: filter_date_end,
                                                messages: job_msg_queue,
                                                verbose: verbose,
                                                debug_verbose: find_and_fix_job_debug_verbose,
                                                task: task )
    timestamp_end = DateTime.now
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "job_msg_queue=#{job_msg_queue}",
                                           "timestamp_end=#{timestamp_end}",
                                           "" ], bold_puts: task if find_and_fix_job_debug_verbose
    job_msg_queue.each { |msg| puts msg } if task
    email_results( task_name: "Find and Fixer", event: 'find and fixer job' )
  rescue Exception => e # rubocop:disable Lint/RescueException
    Rails.logger.error "#{e.class} #{e.message} at #{e.backtrace[0]}"
    Rails.logger.error e.backtrace[0..20].join("\n")
    email_failure( task_name: "find and fix job", exception: e, event: 'find and fix' )
    raise e
  end

end
