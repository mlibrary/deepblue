# frozen_string_literal: true

require_relative '../services/deepblue/works_reporter'

class WorksReportJob < ::Deepblue::DeepblueJob

  mattr_accessor :works_report_job_debug_verbose,
                 default: ::Deepblue::JobTaskHelper.works_report_job_debug_verbose

SCHEDULER_ENTRY = <<-END_OF_SCHEDULER_ENTRY

works_report_job_monthly:
  # Run once a day, five minutes after midnight (which is offset by 4 or [5 during daylight savings time], due to GMT)
  #      M H D
  # cron: '*/5 * * * *'
  cron: '5 5 1 * *'
  class: WorksReportJob
  queue: scheduler
  description: Works report job.
  args:
    hostnames:
      - 'deepblue.lib.umich.edu'
      - 'staging.deepblue.lib.umich.edu'
      - 'testing.deepblue.lib.umich.edu'
    quiet: true
    report_file_prefix: '%date%.%hostname%.works_report'
    report_dir: '/deepbluedata-dataden/download-prep/reports'
    subscription_service_id: works_report_job_monthly

END_OF_SCHEDULER_ENTRY

  queue_as :scheduler

  attr_accessor :echo_to_stdout, :hostnames, :options, :quiet, :verbose

  def perform( *args )
    initialize_options_from( *args, debug_verbose: works_report_job_debug_verbose )
    # timestamp_begin
    # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
    #                                        ::Deepblue::LoggingHelper.called_from,
    #                                        "" ] if works_report_job_debug_verbose
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name, event: "works report job" )
    # ::Deepblue::JobTaskHelper.has_options( *args, job: self, debug_verbose: works_report_job_debug_verbose )
    # ::Deepblue::JobTaskHelper.is_verbose( job: self, debug_verbose: works_report_job_debug_verbose )
    # ::Deepblue::JobTaskHelper.is_quiet( job: self, debug_verbose: works_report_job_debug_verbose )
    return unless hostname_allowed
    # test = job_options_value( key: 'test', default_value: true )
    # if quiet
    #   echo_to_stdout = false
    #   to_console = false
    #   options['to_console'] = false
    # else
    #   echo_to_stdout = job_options_value( key: 'echo_to_stdout', default_value: false )
    #   logging = job_options_value( key: 'logging', default_value: false )
    #   to_console = job_options_value( key: 'to_console' )
    #   to_console = echo_to_stdout if echo_to_stdout.present? && to_console.blank?
    #   options['to_console'] = to_console
    # end
    # msg_handler = ::Deepblue::MessageHandler.new( msg_queue: job_msg_queue, to_console: to_console )
    reporter = ::Deepblue::WorksReporter.new( msg_handler: msg_handler, options: options )
    reporter.run
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, rails_log: true, args: args )
    email_failure( task_name: task_name, exception: e, event: event_name )
    raise e
  end

end
