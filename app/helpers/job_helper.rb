# frozen_string_literal: true

module JobHelper

  mattr_accessor :job_helper_debug_verbose, default: ::Deepblue::JobTaskHelper.job_helper_debug_verbose


  attr_writer   :debug_verbose
  attr_writer   :email_targets
  attr_writer   :from_dashboard
  attr_writer   :hostname
  attr_writer   :hostname_allowed
  attr_writer   :hostnames
  attr_writer   :job_delay
  attr_accessor :job_status
  attr_writer   :msg_handler
  attr_accessor :options
  attr_accessor :restartable
  attr_writer   :subscription_service_id
  attr_writer   :task_name
  attr_writer   :timestamp_begin
  attr_writer   :timestamp_end

  def by_request_only
    @by_request_only ||= job_options_value( key: 'by_request_only', default_value: false )
  end
  alias :by_request_only? :by_request_only

  def debug_verbose
    @debug_verbose ||= job_helper_debug_verbose
  end
  alias :debug_verbose? :debug_verbose

  def default_value_is( value, default_value = nil )
    return value if value.present?
    default_value
  end

  def email_all_targets( task_name:,
                         event:,
                         subject: nil,
                         body: nil,
                         content_type: nil )

    msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                             ::Deepblue::LoggingHelper.called_from,
                             "task_name=#{task_name}",
                             "email_targets=#{email_targets}",
                             "" ] if msg_handler.debug_verbose
    body = msg_handler.join( "\n" ) if body.blank?
    if from_dashboard.present? # just email user running the job from the dashboard
      ::Deepblue::JobTaskHelper.send_email( email_target: from_dashboard,
                                            task_name: task_name,
                                            event: event,
                                            subject: subject,
                                            body: body,
                                            content_type: content_type,
                                            msg_handler: msg_handler )
    else
      email_targets.each do |email_target|
        ::Deepblue::JobTaskHelper.send_email( email_target: email_target,
                                              task_name: task_name,
                                              event: event,
                                              subject: subject,
                                              body: body,
                                              content_type: content_type,
                                              msg_handler: msg_handler )
      end
    end
  end

  def email_failure( targets: email_targets,
                     task_name: self.class.name,
                     exception:,
                     event: self.class.name,
                     event_note: '',
                     timestamp_begin: self.timestamp_begin,
                     timestamp_end: self.timestamp_end )

    msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                             ::Deepblue::LoggingHelper.called_from,
                             "targets=#{targets}",
                             "task_name=#{task_name}",
                             "msg_handler.msg_queue=#{msg_handler.msg_queue}",
                             "" ] if msg_handler.debug_verbose
    targets = email_failure_targets( from_dashboard: from_dashboard, targets: targets )
    return unless targets.present?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "targets=#{targets}",
                                           "" ] if debug_verbose
    lines = msg_handler.join
    ::Deepblue::JobTaskHelper.email_failure( targets: targets,
                                             task_name: task_name,
                                             exception: exception,
                                             event: event,
                                             event_note: event_note,
                                             timestamp_begin: timestamp_begin,
                                             timestamp_end: timestamp_end,
                                             msg_handler: msg_handler,
                                             debug_verbose: msg_handler.debug_verbose )
  end

  def email_failure_targets( from_dashboard: [], targets: [] )
    targets = Array(targets) + email_targets
    targets.uniq!
    ::Deepblue::JobTaskHelper.email_failure_targets( from_dashboard: from_dashboard,
                                                     msg_handler: msg_handler,
                                                     targets: targets,
                                                     debug_verbose: msg_handler.debug_verbose )
  end

  def email_results( targets: [],
                     task_name: self.class.name,
                     event: self.class.name, event_note: '',
                     timestamp_begin: self.timestamp_begin,
                     timestamp_end: self.timestamp_end )

    msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                             ::Deepblue::LoggingHelper.called_from,
                             "targets=#{targets}",
                             "email_targets=#{email_targets}",
                             "task_name=#{task_name}",
                             "msg_handler.msg_queue=#{msg_handler.msg_queue}",
                             "" ] if msg_handler.debug_verbose
    targets = Array(targets) + email_targets
    targets.uniq!
    return unless targets.present?
    ::Deepblue::JobTaskHelper.email_results( targets: targets,
                                             task_name: task_name,
                                             event: event,
                                             event_note: event_note,
                                             messages: msg_handler.msg_queue,
                                             timestamp_begin: timestamp_begin,
                                             timestamp_end: timestamp_end,
                                             msg_handler: msg_handler,
                                             debug_verbose: msg_handler.debug_verbose )
  end

  def email_targets
    @email_targets ||= []
  end

  def email_targets_add( targets )
    targets = Array( targets )
    return unless targets.present?
    @email_targets ||= []
    @email_targets << targets
    @email_targets.flatten!
    @email_targets.uniq!
  end

  def email_targets_init( keys: ['email_results_to', 'user_email'] )
    msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                             ::Deepblue::LoggingHelper.called_from,
                             "email_targets=#{email_targets}",
                             "" ] if msg_handler.debug_verbose
    email_targets_to_add = []
    keys.each do |key|
      email_target = job_options_value( key: key, default_value: [] )
      next if email_target.blank?
      msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                               ::Deepblue::LoggingHelper.called_from,
                               "email_target=#{email_target}",
                               "" ] if msg_handler.debug_verbose
      email_targets_to_add << email_target
    end
    email_targets_add email_targets_to_add
    id = subscription_service_id
    if id.present?
      @email_targets = ::Deepblue::EmailSubscriptionService.merge_targets_and_subscribers( targets: @email_targets,
                                                                                    subscription_service_id: id )
    end
    msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                             ::Deepblue::LoggingHelper.called_from,
                             "email_targets=#{email_targets}",
                             "" ] if msg_handler.debug_verbose
  end

  def event_name
    self.class.name
  end

  def find_all_email_targets( additional_email_targets: [] )
    # self.email_targets = self.email_targets | additional_email_targets # union of arrays and remove duplicates
    email_targets_add additional_email_targets
  end

  def from_dashboard
    @from_dashboard ||= from_dashboard_init
  end
  alias :from_dashboard? :from_dashboard

  def from_dashboard_init
    job_options_value( key: 'from_dashboard', default_value: '' )
  end

  def hostname
    @hostname ||= Rails.configuration.hostname
  end

  def hostname_allowed
    @hostname_allowed ||= hostname_allowed_init
  end
  alias :hostname_allowed? :hostname_allowed

  def hostname_allowed_init
    return true if hostnames.blank?
    hostnames.include? hostname
  end

  def hostnames
    @hostnames ||= hostnames_init
  end

  def hostnames_init
    job_options_value( key: 'hostnames', default_value: [] )
  end

  def initialize_options_from( *args, id: nil, debug_verbose: job_helper_debug_verbose )
    debug_verbose = debug_verbose || job_helper_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "args=#{args}",
                                           "id=#{id}",
                                           "debug_verbose=#{debug_verbose}",
                                           "" ] if debug_verbose
    @options = ::Deepblue::JobTaskHelper.initialize_options_from( *args, debug_verbose: debug_verbose )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@options=#{@options}",
                                           "" ] if debug_verbose
    initialize_defaults( debug_verbose: debug_verbose )
    by_request_only
    job_status_init( id: id )
    email_targets_init
    timestamp_begin
    return @options
  end

  def initialize_with( id: nil, debug_verbose: job_helper_debug_verbose, options: {} )
    debug_verbose = debug_verbose || msg_handler.debug_verbose  || job_helper_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "debug_verbose=#{debug_verbose}",
                                           "options=#{options}",
                                           "" ] if debug_verbose
    @options = options
    initialize_defaults( debug_verbose: debug_verbose )
    job_status_init( id: id )
    timestamp_begin
  end

  def init_from_arg( arg:, default_var: nil, default_value: nil )
    default_value = default_value_is( default_var, default_value )
    job_options_value( key: arg, default_value: default_value )
  end

  def initialize_defaults( debug_verbose: job_helper_debug_verbose )
    debug_verbose = debug_verbose || job_helper_debug_verbose
    @debug_verbose = debug_verbose
    @options ||= {}
    @options = @options.with_indifferent_access if @options.is_a? Hash
    self.quiet
    self.task
    self.verbose
    self.msg_handler # must be called after quiet, task, and verbose
    msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                             ::Deepblue::LoggingHelper.called_from,
                             "options=#{options}",
                             "" ] if msg_handler.debug_verbose
  end

  def initialize_no_args_hash( id: nil, debug_verbose: job_helper_debug_verbose )
    debug_verbose = debug_verbose || job_helper_debug_verbose
    initialize_defaults( debug_verbose: debug_verbose )
    job_status_init( id: id )
    email_targets_init
    timestamp_begin
    return @options
  end

  def job_delay
    @job_delay ||= job_delay_init
  end

  def job_delay_init
    job_options_value( key: 'job_delay', default_value: 0 )
  end

  def job_msg_queue
    msg_handler.msg_queue
  end

  def job_options_keys_found
    @job_options_keys_found ||= []
  end

  def job_options_key?( key: )
    return false if options.blank?
    return options.key? key
  end

  def job_options_value( key:, default_value: nil, no_msg_handler: false )
    raise "No options defined." if @options.nil?
    return default_value if @options.blank?
    return default_value unless @options.key? key
    @job_options_keys_found ||= []
    @job_options_keys_found << key
    rv = @options[key]
    if no_msg_handler
      ::Deepblue::LoggingHelper.debug "#{key}=#{rv}" if debug_verbose
    else
      msg_handler.msg_verbose( "set key #{key} to #{rv}", log: 'debug' )
    end
    return rv
  end
  # alias :options_value :job_options_value

  def job_finished
    msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                             ::Deepblue::LoggingHelper.called_from,
                             "" ] if debug_verbose
    job_status.add_messages( msg_handler.msg_queue )
    job_status.finished!
    return @job_status
  end

  def job_status_init( id: nil, restartable: false )
    msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                             ::Deepblue::LoggingHelper.called_from,
                             "id=#{id}",
                             "restartable=#{restartable}",
                             "" ] if msg_handler.debug_verbose
    @restartable = restartable
    @job_status = JobStatus.find_or_create_job_started( job: self, main_cc_id: id )
    msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                             ::Deepblue::LoggingHelper.called_from,
                             "job_status=#{job_status}",
                             "" ] if msg_handler.debug_verbose
    @job_status
  end

  def job_status_register( exception:,
                           msg: nil,
                           args: '',
                           rails_log: true,
                           status: nil,
                           backtrace: 20 )

    msg = "Exception #{exception.message} encountered while processing: #{self.class.name}.perform(#{args})" if msg.blank?
    msg_handler.msg_error( msg, log: rails_log )
    msg_handler.msg_exception( exception, log: rails_log, backtrace: backtrace )
    job_status = JobStatus.find_or_create_job_error( job: self, error: msg )
    return job_status if job_status.nil?
    job_status.add_messages( msg_handler.msg_queue )
    job_status.add_message!( msg )
    return job_status.status! status unless status.nil?
    return job_status.status! JobStatus::FINISHED unless restartable
    job_status
  end
  alias :job_status_error :job_status_register

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

  def msg_handler
    @msg_handler ||= msg_handler_init
  end

  def msg_handler_init
    rv = ::Deepblue::MessageHandler.new( debug_verbose: debug_verbose, to_console: @task, verbose: @verbose )
    rv.quiet = @quiet
    return rv
  rescue Exception => e
    msg = "#{e.class}: #{e.message} at #{e.backtrace.join("\n")}"
    # rubocop:disable Rails/Output
    puts msg
    # rubocop:enable Rails/Output
    Rails.logger.error msg
    return ::Deepblue::MessageHandler.new
  end

  def quiet
    @quiet ||= quiet_init
  end
  alias :quiet? :quiet

  def quiet_init
    job_options_value( key: 'quiet', default_value: false, no_msg_handler: true )
  end

  alias :restartable? :restartable

  def queue_exception_msgs( exception, include_backtrace: true )
    msg_handler.msg_exception exception
  end

  def queue_msg_more( test_result, msg:, more_msgs: )
    msg_handler.msg_with_rv( test_result, msg: Array(msg) + Array(more_msgs) )
  end

  def queue_msg_if?( test_result, msg, more_msgs: [] )
    msg_handler.msg_if?(  test_result, msg: Array(msg) + Array(more_msgs) )
  end

  def queue_msg_unless?( test_result, msg, more_msgs: [] )
    msg_handler.msg_unless?(  test_result, msg: Array(msg) + Array(more_msgs) )
  end

  def subscription_service_id
    @subscription_service_id ||= job_options_value( key: 'subscription_service_id', default_value: nil )
  end

  def timestamp_begin
    @timestamp_begin ||= DateTime.now
  end

  def timestamp_end
    @timestamp_end ||= DateTime.now
  end

  def task
    @task ||= task_init
  end

  def task_init
    job_options_value( key: 'task', default_value: false, no_msg_handler: true )
  end

  def task_name
    @task_name ||= self.class.name.titlecase
  end

  def verbose
    @verbose ||= verbose_init
  end
  alias :verbose? :verbose

  def verbose_init
    job_options_value( key: 'verbose', default_value: false, no_msg_handler: true )
  end

end
