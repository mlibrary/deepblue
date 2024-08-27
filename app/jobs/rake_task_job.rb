# frozen_string_literal: true

require "abstract_rake_task_job"

class RakeTaskJob < AbstractRakeTaskJob

  # bundle exec rake deepblue:run_job['{"job_class":"RakeTaskJob"\,"verbose":true\,"rake_task":"-T"\,"email_results_to":["fritx@umich.edu"]\,"job_delay":0}']
  # bundle exec rake deepblue:run_job['{"job_class":"RakeTaskJob"\,"verbose":true\,"rake_task":"tmp:clean"\,"email_results_to":["fritx@umich.edu"]}']
  # bundle exec rake deepblue:run_job['{"job_class":"RakeTaskJob"\,"verbose":true\,"rake_task":"blacklight:delete_old_searches[30]"\,"email_results_to":["fritx@umich.edu"]}']

  mattr_accessor :rake_task_job_debug_verbose, default: ::Deepblue::JobTaskHelper.rake_task_job_debug_verbose
  mattr_accessor :rake_task_job_bold_puts, default: false

  # queue_as :scheduler

SCHEDULER_ENTRY = <<-END_OF_SCHEDULER_ENTRY

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
    is_quiet: true
    verbose: false

END_OF_SCHEDULER_ENTRY

  attr_accessor :rake_task

  def self.perform( *args )
    RakeTaskJob.perform_now( *args )
  end

  def perform( *args )
    debug_verbose = rake_task_job_debug_verbose
    initialized = initialize_from_args( args: args, debug_verbose: debug_verbose )
    @is_quiet = job_options_value( key: 'is_quiet', default_value: false )
    msg_handler.quiet = @is_quiet
    @rake_task = job_options_value( key: 'rake_task', default_value: "" )
    return if !initialized || @rake_task.blank?
    msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                             ::Deepblue::LoggingHelper.called_from,
                             "options=#{options}",
                             "job_options_keys_found=#{job_options_keys_found}",
                             "verbose=#{verbose}",
                             "hostnames=#{hostnames}",
                             "email_targets=#{email_targets}",
                             # "initialized=#{initialized}",
                             "job_delay=#{job_delay}",
                             "rake_task=#{rake_task}",
                             "allowed_job_tasks.include? #{rake_task}=#{::Deepblue::JobTaskHelper.allowed_job_tasks.include? rake_task}",
                             "" ] if debug_verbose
    return unless allowed_job_task?
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name, event_note: rake_task )
    run_job_delay
    exec_str = "bundle exec rake #{rake_task}"
    rv = exec_rake_task( exec_str )
    timestamp_end = DateTime.now
    msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                             ::Deepblue::LoggingHelper.called_from,
                             "timestamp_end=#{timestamp_end}",
                             "rv=#{rv}",
                             "" ] if debug_verbose
    email_exec_results( exec_str: exec_str, rv: rv, event: 'rake task job', event_note: rake_task ) unless @is_quiet
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: args, rails_log: true )
    email_failure( task_name: exec_str,
                   exception: e,
                   event: 'rake task job',
                   event_note: rake_task )
    raise e
  end

  def exec_rake_task( exec_str )
    `#{exec_str}`
  end

  def allowed_job_task?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "rake_task=#{rake_task}",
                                           "" ], bold_puts: rake_task_job_bold_puts if rake_task_job_debug_verbose
    return true if ::Deepblue::JobTaskHelper.allowed_job_tasks.include? rake_task
    ::Deepblue::JobTaskHelper.allowed_job_task_matching.each do |matcher|
      rv = matcher =~ rake_task
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rake_task=#{rake_task}",
                                             "matcher=#{matcher}",
                                             "rv=#{rv}",
                                             "" ], bold_puts: rake_task_job_bold_puts if rake_task_job_debug_verbose
      return true if rv
    end
    return false
  end

  # def self.queue
  #   :default
  # end

end
