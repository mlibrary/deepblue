# frozen_string_literal: true

require "abstract_rake_task_job"

class RakeTaskJob < AbstractRakeTaskJob

  # bundle exec rake deepblue:run_job['{"job_class":"RakeTaskJob"\,"verbose":true\,"rake_task":"-T"\,"email_results_to":["fritx@umich.edu"]\,"job_delay":0}']
  # bundle exec rake deepblue:run_job['{"job_class":"RakeTaskJob"\,"verbose":true\,"rake_task":"tmp:clear"\,"email_results_to":["fritx@umich.edu"]}']

  mattr_accessor :rake_task_job_debug_verbose, default: ::Deepblue::JobTaskHelper.rake_task_job_debug_verbose

  # queue_as :scheduler

EXAMPLE_SCHEDULER_ENTRY = <<-END_OF_EXAMPLE_SCHEDULER_ENTRY

example_rake_task_job:
# Run once a day, five minutes after midnight (which is offset by 4 or [5 during daylight savings time], due to GMT)
#       M H D
# cron: '*/5 * * * *'
  cron: '5 5 1 * *'
  class: RakeTaskJob
  queue: scheduler
  description: Description of rake task job.
  args:
    rake_task: 'tmp:clean'
    hostnames:
      - 'deepblue.lib.umich.edu'
      - 'staging.deepblue.lib.umich.edu'
      - 'testing.deepblue.lib.umich.edu'
    email_results_to:
      - 'fritx@umich.edu'
    verbose: true 

END_OF_EXAMPLE_SCHEDULER_ENTRY

  attr_accessor :rake_task

  def self.perform( *args )
    RakeTaskJob.perform_now( *args )
  end

  def perform( *args )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "args=#{args}",
                                           "" ] if rake_task_job_debug_verbose
    initialized = initialize_from_args( *args )
    rake_task = job_options_value( options, key: 'rake_task', default_value: "", verbose: verbose )
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name, event_note: rake_task )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "options=#{options}",
                                           "job_options_keys_found=#{job_options_keys_found}",
                                           "verbose=#{verbose}",
                                           "hostnames=#{hostnames}",
                                           "email_targets=#{email_targets}",
                                           "initialized=#{initialized}",
                                           "job_delay=#{job_delay}",
                                           "rake_task=#{rake_task}",
                                           "allowed_job_tasks.include? #{rake_task}=#{::Deepblue::JobTaskHelper.allowed_job_tasks.include? rake_task}",
                                           "" ] if rake_task_job_debug_verbose
    return unless initialized
    return if rake_task.blank?
    return unless allowed_job_task?
    run_job_delay
    exec_str = "bundle exec rake #{rake_task}"
    rv = exec_rake_task( exec_str )
    timestamp_end = DateTime.now
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "timestamp_end=#{timestamp_end}",
                                           "rv=#{rv}",
                                           "" ] if rake_task_job_debug_verbose
    email_exec_results( exec_str: exec_str, rv: rv, event: 'rake task job', event_note: rake_task )
  rescue Exception => e # rubocop:disable Lint/RescueException
    Rails.logger.error "#{e.class} #{e.message} at #{e.backtrace[0]}"
    Rails.logger.error e.backtrace[0..20].join("\n")
    email_failure( task_name: exec_str, exception: e, event: 'rake task job', event_note: rake_task )
    raise e
  end

  def exec_rake_task( exec_str )
    `#{exec_str}`
  end

  def allowed_job_task?
    ::Deepblue::JobTaskHelper.allowed_job_tasks.include? rake_task
  end

  # def self.queue
  #   :default
  # end

end
