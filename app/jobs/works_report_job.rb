# frozen_string_literal: true

require_relative '../services/deepblue/works_reporter'

class WorksReportJob < ::Hyrax::ApplicationJob

  WORKS_REPORT_JOB_DEBUG_VERBOSE = ::Deepblue::JobTaskHelper.works_report_job_debug_verbose

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
    report_dir: '/deepbluedata-prep/reports'
    subscription_service_id: works_report_job_monthly

END_OF_SCHEDULER_ENTRY


  include JobHelper
  queue_as :scheduler

  attr_accessor :echo_to_stdout, :hostname, :hostnames, :options, :quiet, :verbose

  def perform( *args )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if WORKS_REPORT_JOB_DEBUG_VERBOSE
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name, event: "works report job" )
    ::Deepblue::JobTaskHelper.has_options( *args, job: self, debug_verbose: WORKS_REPORT_JOB_DEBUG_VERBOSE )
    ::Deepblue::JobTaskHelper.is_verbose( job: self, debug_verbose: WORKS_REPORT_JOB_DEBUG_VERBOSE )
    ::Deepblue::JobTaskHelper.is_quiet( job: self, debug_verbose: WORKS_REPORT_JOB_DEBUG_VERBOSE )
    return unless ::Deepblue::JobTaskHelper.hostname_allowed( job: self, debug_verbose: WORKS_REPORT_JOB_DEBUG_VERBOSE )
    test = job_options_value( options, key: 'test', default_value: true, verbose: verbose )
    if quiet
      echo_to_stdout = false
      options['to_console'] = false
    else
      echo_to_stdout = job_options_value( options, key: 'echo_to_stdout', default_value: false, verbose: verbose )
      logging = job_options_value( options, key: 'logging', default_value: false, verbose: verbose )
      to_console = job_options_value( options, key: 'to_console', verbose: verbose )
      options['to_console'] = echo_to_stdout if echo_to_stdout.present? && to_console.blank?
    end
    reporter = ::Deepblue::WorksReporter.new( options: options )
    reporter.run
  rescue Exception => e # rubocop:disable Lint/RescueException
    Rails.logger.error "#{e.class} #{e.message} at #{e.backtrace[0]}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

end
