# frozen_string_literal: true

class ::Deepblue::DeepblueJob < ::Hyrax::ApplicationJob

  # A common base class for all Hyrax jobs.
  # This allows downstream applications to manipulate all the hyrax jobs by
  # including modules on this class.

  include JobHelper # see JobHelper for :by_request_only, :email_targets, :hostname, :job_msg_queue, :timestamp_begin, :timestamp_end

  mattr_accessor :deepblue_job_debug_verbose, default: ::Deepblue::JobTaskHelper.deepblue_job_debug_verbose

  attr_accessor :by_request_only
  attr_accessor :debug_verbose
  attr_accessor :from_dashboard
  attr_accessor :hostnames
  attr_accessor :is_quiet
  attr_accessor :job_status
  attr_accessor :options
  attr_accessor :quiet
  attr_accessor :restartable
  attr_accessor :task
  attr_accessor :verbose

  def by_request_only
    @by_request_only ||= false
  end
  alias :by_request_only? :by_request_only

  def debug_verbose
    @debug_verbose ||= deepblue_job_debug_verbose
  end
  alias :debug_verbose? :debug_verbose

  def email_all_targets( task_name:,
                         event:,
                         subject: nil,
                         body: nil,
                         content_type: nil,
                         debug_verbose: deepblue_job_debug_verbose )

    if from_dashboard.present? # just email user running the job from the dashboard
      ::Deepblue::JobTaskHelper.send_email( email_target: from_dashboard,
                                            task_name: task_name,
                                            event: event,
                                            subject: subject,
                                            body: body,
                                            content_type: content_type )
    else
      ::Deepblue::JobTaskHelper.has_email_targets( job: self, debug_verbose: debug_verbose, task: task )
      self.email_targets.each do |email_target|
        ::Deepblue::JobTaskHelper.send_email( email_target: email_target,
                                              task_name: task_name,
                                              event: event,
                                              subject: subject,
                                              body: body,
                                              content_type: content_type )
      end
    end
  end

  def find_all_email_targets( additional_email_targets: [] )
    self.email_targets = self.email_targets | additional_email_targets # union of arrays and remove duplicates
  end

  def from_dashboard
    @from_dashboard ||= ::Deepblue::JobTaskHelper.from_dashboard( job: self,
                                                                  options: options,
                                                                  debug_verbose: debug_verbose,
                                                                  task: task  )
  end
  alias :from_dashboard? :from_dashboard

  def hostname_allowed( debug_verbose: deepblue_job_debug_verbose )
    @hostname_allowed = ::Deepblue::JobTaskHelper.hostname_allowed( job: self,
                                                                    options: options,
                                                                    debug_verbose: debug_verbose,
                                                                    task: task )
    @hostname_allowed
  end

  def hostname_allowed?
    @hostname_allowed ||= hostname_allowed( debug_verbose: debug_verbose )
  end

  def init_from_arg( arg:, default_var: nil, default_value: nil, task: @task, verbose: @verbose )
    super( arg: arg, default_var: default_var, default_value: default_value, task: task, verbose: verbose )
  end

  def initialize_with( debug_verbose: deepblue_job_debug_verbose )
    @debug_verbose = debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "debug_verbose=#{debug_verbose}",
                                           "" ] if deepblue_job_debug_verbose || debug_verbose
    @options = {}
    @task = false
    @verbose = false
    job_status_init
    timestamp_begin
  end

  def initialize_email_targets
    user_email = job_options_value( options, key: 'user_email', default_value: '', task: task, verbose: verbose )
    return if user_email.blank?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "user_email=#{user_email}",
                                           "" ] if deepblue_job_debug_verbose || debug_verbose
    email_targets << user_email
  end

  def initialize_options_from( *args, debug_verbose: deepblue_job_debug_verbose )
    @debug_verbose = debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "args=#{args}",
                                           "debug_verbose=#{debug_verbose}",
                                           "" ] if deepblue_job_debug_verbose || debug_verbose
    @options = ::Deepblue::JobTaskHelper.initialize_options_from( args, debug_verbose: debug_verbose )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "options=#{options}",
                                           "" ] if deepblue_job_debug_verbose || debug_verbose
    @task = job_options_value( options, key: 'task', default_value: false, task: false, verbose: false )
    @verbose = job_options_value( options, key: 'verbose', default_value: false, task: @task, verbose: false )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "verbose=#{verbose}",
                                           "" ] if deepblue_job_debug_verbose || debug_verbose
    @by_request_only = job_options_value( options,
                                          key: 'by_request_only',
                                          default_value: false,
                                          task: @task,
                                          verbose: @verbose )
    job_status_init
    initialize_email_targets
    timestamp_begin
    return @options
  end

  def initialize_no_args_hash( debug_verbose: deepblue_job_debug_verbose )
    @debug_verbose = debug_verbose
    @options = {}
    @task = false
    @verbose = false
    job_status_init
    initialize_email_targets
    timestamp_begin
    return @options
  end

  def is_quiet
    @is_quiet ||= ::Deepblue::JobTaskHelper.is_quiet( job: self,
                                                      options: options,
                                                      debug_verbose: @debug_verbose,
                                                      task: task  )
  end
  alias :is_quiet? :is_quiet

  def job_finished
    job_status.add_messages( job_msg_queue )
    job_status.finished!
    return @job_status
  end

  def job_status_init( restartable: false, debug_verbose: deepblue_job_debug_verbose )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "restartable=#{restartable}",
                                           "" ] if debug_verbose || deepblue_job_debug_verbose
    @restartable = restartable
    @job_status = JobStatus.find_or_create_job_started( job: self )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "job_status=#{job_status}",
                                           "" ] if debug_verbose || deepblue_job_debug_verbose
    @job_status
  end

  def job_status_register( exception:, msg: nil, args: '', rails_log: true, status: nil )
    msg = "#{self.class.name}.perform(#{args}) #{exception.class}: #{exception.message}" unless msg.present?
    Rails.logger.error msg if rails_log
    job_status = JobStatus.find_or_create_job_error( job: self, error: msg )
    return job_status if job_status.nil?
    job_status.add_messages( job_msg_queue )
    job_status.add_message!( msg )
    return job_status.status! status unless status.nil?
    return job_status.status! JobStatus::FINISHED unless restartable
    job_status
  end

  def log( event: 'unknown',
           event_note: '',
           id: '',
           hostname_allowed: "N/A",
           timestamp: DateTime.now,
           echo_to_rails_logger: ::Deepblue::SchedulerHelper.scheduler_log_echo_to_rails_logger,
           **log_key_values )

    ::Deepblue::SchedulerHelper.log( class_name: self.class.name,
                                     event: event,
                                     event_note: event_note,
                                     id: id,
                                     hostname_allowed: hostname_allowed,
                                     timestamp: timestamp,
                                     echo_to_rails_logger: echo_to_rails_logger,
                                     **log_key_values )
  end

  alias :restartable? :restartable
  alias :verbose? :verbose

  def task
    @task ||= false
  end

end
