# frozen_string_literal: true

require_relative '../../lib/tasks/task_logger'
require_relative '../../lib/tasks/abstract_task'
require_relative '../../lib/tasks/abstract_report_task'
require_relative '../../lib/tasks/report_task'

class ReportTaskJob < ::Hyrax::ApplicationJob

  mattr_accessor :report_task_job_debug_verbose
  @@report_task_job_debug_verbose = true # ::Deepblue::IngestIntegrationService.report_task_job_debug_verbose

  mattr_accessor :report_task_allowed_path_extensions
  @@report_task_allowed_path_extensions = [ '.yml', '.yaml' ]

  mattr_accessor :report_task_allowed_path_prefixes
  @@report_task_allowed_path_prefixes = [ '/deepbluedata-prep/', './data/reports/', '/deepbluedata-globus/uploads/' ]

  include JobHelper # see JobHelper for :email_targets, :hostname, :job_msg_queue, :timestamp_begin, :timestamp_end
  queue_as :default

  attr_accessor :options, :reporter, :report_file_path

  def perform(  reporter:, report_file_path:, **options )
    timestamp_begin
    email_targets << reporter if reporter.present?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "reporter=#{reporter}",
                                           "report_file_path=#{report_file_path}",
                                           "options=#{options}",
                                           "email_targets=#{email_targets}",
                                           "" ] if report_task_job_debug_verbose
    init_report_file_path report_file_path
    @reporter = reporter
    @options = options
    return email_failure( exception: nil ) unless queue_msg_unless?( self.report_file_path.present?,
                                                                     "ERROR: Report file path '#{self.report_file_path}' not found." )
    return email_failure( exception: nil ) unless validate_report_file_path
    run_report
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "job_msg_queue=#{job_msg_queue}",
                                           "" ] if report_task_job_debug_verbose
    email_results
  rescue Exception => e # rubocop:disable Lint/RescueException
    # Rails.logger.error "#{e.class} #{e.message} at #{e.backtrace[0]}"
    # Rails.logger.error e.backtrace.join("\n")
    # raise e
    queue_exception_msgs e
    email_failure( exception: e, targets: [reporter] )
    raise e
  end

  def run_report
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                          ::Deepblue::LoggingHelper.called_from,
                                           "report_file_path=#{report_file_path}",
                                           "" ] if report_task_job_debug_verbose
    return false if queue_msg_if?( report_file_path.blank?, "ERROR: Report file path is blank." )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "ReportTasktJob.perform_now( report_file_path: #{report_file_path}, reporter: #{reporter} )",
                                           "" ] if report_task_job_debug_verbose
    task = ::Deepblue::ReportTask.new( report_definitions_file: report_file_path,
                                       reporter: reporter,
                                       allowed_path_extensions: report_task_allowed_path_extensions,
                                       allowed_path_prefixes: report_task_allowed_path_prefixes,
                                       msg_queue: job_msg_queue,
                                       verbose: false,
                                       options: options )
    task.run
    true
  end

  def init_report_file_path( path )
    @report_file_path = path
  end

  def validate_report_file_path
    file = report_file_path
    return false unless queue_msg_unless?( file.present?, "ERROR: file path empty." )
    return false unless queue_msg_unless?( File.exist?( file ), "ERROR: file '#{file}' not found." )
    ext = File.extname file
    return false unless queue_msg_unless?( report_task_allowed_path_extensions.include?( ext ),
                                           "ERROR: expected file '#{file}' to have one of these extensions:",
                                           more_msgs: report_task_allowed_path_extensions )
    allowed = false
    report_task_allowed_path_prefixes.each do |prefix|
      if file.start_with? prefix
        allowed = true
        break
      end
    end
    return false unless queue_msg_unless?( allowed,
                                           "ERROR: expected file '#{file}' path to start with:",
                                           more_msgs: report_task_allowed_path_prefixes )
    return true
  end

end
