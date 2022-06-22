# frozen_string_literal: true

module JobHelper

  mattr_accessor :job_helper_debug_verbose, default: ::Deepblue::JobTaskHelper.job_helper_debug_verbose

  attr_accessor :by_request_only
  attr_accessor :email_targets
  attr_accessor :hostname
  attr_accessor :job_msg_queue
  attr_accessor :timestamp_begin
  attr_accessor :timestamp_end

  def by_request_only
    @by_request_only ||= false
  end
  alias :by_request_only? :by_request_only

  def default_value_is( value, default_value = nil )
    return value if value.present?
    default_value
  end

  def email_targets
    @email_targets ||= []
  end

  def email_targets_add( targets )
    targets = Array( targets )
    return unless targets.present?
    @email_targets << targets
    @email_targets.flatten!
  end

  def hostname
    @hostname ||= Rails.configuration.hostname
  end

  def job_msg_queue
    @job_msg_queue ||= []
  end

  def timestamp_begin
    @timestamp_begin ||= DateTime.now
  end

  def timestamp_end
    @timestamp_end ||= DateTime.now
  end

  def email_failure( targets: email_targets,
                     task_name: self.class.name,
                     exception:,
                     event: self.class.name,
                     event_note: '',
                     timestamp_begin: self.timestamp_begin,
                     timestamp_end: self.timestamp_end,
                     msg_handler: nil,
                     debug_verbose: job_helper_debug_verbose )

    debug_verbose = debug_verbose || job_helper_debug_verbose || (msg_handler.nil? ? false : msg_handler.debug_verbose)
    to_console = (msg_handler.nil? ? false : msg_handler.to_console)
   ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "targets=#{targets}",
                                           "task_name=#{task_name}",
                                           "job_msg_queue=#{job_msg_queue}",
                                           "" ], bold_puts: to_console if debug_verbose
    targets = email_failure_targets( from_dashboard: from_dashboard,
                                     msg_handler: msg_handler,
                                     targets: targets,
                                     debug_verbose: debug_verbose )
    return unless targets.present?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "targets=#{targets}",
                                           "" ] if debug_verbose
    ::Deepblue::JobTaskHelper.email_failure( targets: targets,
                                             task_name: task_name,
                                             exception: exception,
                                             event: event,
                                             event_note: event_note,
                                             messages: job_msg_queue,
                                             timestamp_begin: timestamp_begin,
                                             timestamp_end: timestamp_end,
                                             msg_handler: msg_handler,
                                             debug_verbose: debug_verbose )
  end

  def email_failure_targets( from_dashboard: [],
                             msg_handler: nil,
                             targets: [],
                             debug_verbose: job_helper_debug_verbose )

    debug_verbose = debug_verbose || job_helper_debug_verbose
    targets = Array(targets) + email_targets
    targets.uniq!
    ::Deepblue::JobTaskHelper.email_failure_targets( from_dashboard: from_dashboard,
                                                     msg_handler: msg_handler,
                                                     targets: targets,
                                                     debug_verbose: debug_verbose )
  end

  def email_results( targets: [],
                     task_name: self.class.name,
                     event: self.class.name, event_note: '',
                     timestamp_begin: self.timestamp_begin,
                     timestamp_end: self.timestamp_end,
                     msg_handler: nil,
                     debug_verbose: job_helper_debug_verbose )

    debug_verbose = debug_verbose || job_helper_debug_verbose || (msg_handler.nil? ? false : msg_handler.debug_verbose)
    to_console = (msg_handler.nil? ? false : msg_handler.to_console)
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "targets=#{targets}",
                                           "email_targets=#{email_targets}",
                                           "task_name=#{task_name}",
                                           "job_msg_queue=#{job_msg_queue}",
                                           "" ], bold_puts: to_console if debug_verbose
    targets = Array(targets) + email_targets
    targets.uniq!
    return unless targets.present?
    ::Deepblue::JobTaskHelper.email_results( targets: targets,
                                             task_name: task_name,
                                             event: event,
                                             event_note: event_note,
                                             messages: job_msg_queue,
                                             timestamp_begin: timestamp_begin,
                                             timestamp_end: timestamp_end,
                                             msg_handler: msg_handler,
                                             debug_verbose: debug_verbose )
  end

  def job_options_keys_found
    @job_options_keys_found ||= []
  end

  def job_options_key?( options, key:, task: false, verbose: false )
    return false if options.blank?
    return options.key? key
  end

  def job_options_value( options, key:, default_value: nil, task: false, verbose: false )
    # ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here,
    #                                        ::Deepblue::LoggingHelper.called_from,
    #                                       "options=#{options}",
    #                                       "key=#{key}",
    #                                       "default_value=#{default_value}",
    #                                       "verbose=#{verbose}",
    #                                        "" ] if job_helper_debug_verbose
    return default_value if options.blank?
    return default_value unless options.key? key
    # if [true, false].include? default_value
    #   return options[key].to_bool
    # end
    @job_options_keys_found ||= []
    @job_options_keys_found << key
    ::Deepblue::LoggingHelper.debug "set key #{key} to #{options[key]}" if verbose
    puts "set key #{key} to #{options[key]}" if verbose && task
    return options[key]
  end

  def init_from_arg( arg:, default_var: nil, default_value: nil, task: @task, verbose: false )
    default_value = default_value_is( default_var, default_value )
    job_options_value( options, key: arg, default_value: default_value, task: task, verbose: verbose )
  end

  def queue_exception_msgs( exception, include_backtrace: true, msg_handler: nil )
    if msg_handler.present?
      msg_handler.msg_exception exception
      return
    end
    job_msg_queue << "#{exception.class} #{exception.message} at #{exception.backtrace[0]}"
    exception.backtrace.each { |line| job_msg_queue << line } if include_backtrace
  end

  def queue_msg_more( test_result, msg:, more_msgs:, msg_handler: nil )
    if msg_handler.present?
      return msg_handler.msg_with_rv( test_result, msg: Array(msg) + Array(more_msgs) )
    end
    job_msg_queue << msg
    Array( more_msgs ).each { |line| job_msg_queue << line } if more_msgs.present?
    return test_result
  end

  def queue_msg_if?( test_result, msg, more_msgs: [], msg_handler: nil )
    if msg_handler.present?
      return msg_handler.msg_if?(  test_result, msg: Array(msg) + Array(more_msgs) )
    end
    queue_msg_more( test_result, msg: msg, more_msgs: more_msgs ) if test_result
    return test_result
  end

  def queue_msg_unless?( test_result, msg, more_msgs: [], msg_handler: nil )
    if msg_handler.present?
      return msg_handler.msg_unless?(  test_result, msg: Array(msg) + Array(more_msgs) )
    end
    queue_msg_more( test_result, msg: msg, more_msgs: more_msgs ) unless test_result
    return test_result
  end

end