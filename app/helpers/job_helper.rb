# frozen_string_literal: true

module JobHelper

  mattr_accessor :job_helper_debug_verbose, default: false

  attr_accessor :email_targets

  def email_targets
    @email_targets ||= []
  end

  attr_accessor :hostname

  def hostname
    @hostname ||= ::DeepBlueDocs::Application.config.hostname
  end

  attr_accessor :job_msg_queue

  def job_msg_queue
    @job_msg_queue ||= []
  end

  attr_accessor :timestamp_begin, :timestamp_end

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
                     timestamp_end: self.timestamp_end )

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "targets=#{targets}",
                                           "task_name=#{task_name}",
                                           "job_msg_queue=#{job_msg_queue}",
                                           "" ] if job_helper_debug_verbose
    targets = [] if targets.blank?
    targets = ::Deepblue::JobTaskHelper.job_failure_email_subscribers & targets
    return unless targets.present?
    return unless targets[0].present?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "targets=#{targets}",
                                           "" ] if job_helper_debug_verbose
    ::Deepblue::JobTaskHelper.email_failure( targets: targets,
                                             task_name: task_name,
                                             exception: exception,
                                             event: event,
                                             event_note: event_note,
                                             messages: job_msg_queue,
                                             timestamp_begin: timestamp_begin,
                                             timestamp_end: timestamp_end )
  end

  def email_results( targets: email_targets,
                     task_name: self.class.name,
                     event: self.class.name, event_note: '',
                     timestamp_begin: self.timestamp_begin,
                     timestamp_end: self.timestamp_end )

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "targets=#{targets}",
                                           "email_targets=#{email_targets}",
                                           "task_name=#{task_name}",
                                           "job_msg_queue=#{job_msg_queue}",
                                           "" ] if job_helper_debug_verbose
    return unless targets.present?
    ::Deepblue::JobTaskHelper.email_results( targets: targets,
                                             task_name: task_name,
                                             event: event,
                                             event_note: event_note,
                                             messages: job_msg_queue,
                                             timestamp_begin: timestamp_begin,
                                             timestamp_end: timestamp_end )
  end

  def job_options_keys_found
    @job_options_keys_found ||= []
  end

  def job_options_value( options, key:, default_value: nil, verbose: false, task: false )
    # ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here,
    #                                        ::Deepblue::LoggingHelper.called_from,
    #                                       "options=#{options}",
    #                                       "key=#{key}",
    #                                       "default_value=#{default_value}",
    #                                       "verbose=#{verbose}",
    #                                        "" ], bold_puts: task if job_helper_debug_verbose
    return default_value if options.blank?
    return default_value unless options.key? key
    # if [true, false].include? default_value
    #   return options[key].to_bool
    # end
    @job_options_keys_found ||= []
    @job_options_keys_found << key
    ::Deepblue::LoggingHelper.debug "set key #{key} to #{options[key]}" if verbose
    puts "set key #{key} to #{options[key]}" if task
    return options[key]
  end

  def queue_exception_msgs( exception, include_backtrace: true )
    e = exception
    job_msg_queue << "#{e.class} #{e.message} at #{e.backtrace[0]}"
    return unless include_backtrace
    e.backtrace.each { |line| job_msg_queue << line }
  end

  def queue_msg_more( test_result, msg:, more_msgs: )
    jmq = job_msg_queue
    jmq << msg
    # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
    #                                        ::Deepblue::LoggingHelper.called_from,
    #                                        "test_result=#{test_result}",
    #                                        "msg=#{msg}",
    #                                        "more_msgs=#{more_msgs}",
    #                                        "job_msg_queue=#{job_msg_queue}",
    #                                        "" ] if job_helper_debug_verbose
    return test_result if more_msgs.blank?
    Array( more_msgs ).each { |line| jmq << line }
    return test_result
  end

  def queue_msg_if?( test_result, msg, more_msgs: [] )
    # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
    #                                        ::Deepblue::LoggingHelper.called_from,
    #                                        "test_result=#{test_result}",
    #                                        "msg=#{msg}",
    #                                        "more_msgs=#{more_msgs}",
    #                                        "job_msg_queue=#{job_msg_queue}",
    #                                        "" ] if job_helper_debug_verbose
    return test_result unless test_result
    return queue_msg_more( test_result, msg: msg, more_msgs: more_msgs )
  end

  def queue_msg_unless?( test_result, msg, more_msgs: [] )
    # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
    #                                        ::Deepblue::LoggingHelper.called_from,
    #                                        "test_result=#{test_result}",
    #                                        "msg=#{msg}",
    #                                        "more_msgs=#{more_msgs}",
    #                                        "job_msg_queue=#{job_msg_queue}",
    #                                        "" ] if job_helper_debug_verbose
    return test_result if test_result
    return queue_msg_more( test_result, msg: msg, more_msgs: more_msgs )
  end

end