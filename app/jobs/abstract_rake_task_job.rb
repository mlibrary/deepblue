# frozen_string_literal: true

class AbstractRakeTaskJob < ::Hyrax::ApplicationJob

  ABSTRACT_RAKE_TASK_JOB_DEBUG_VERBOSE = ::Deepblue::JobTaskHelper.abstract_rake_task_job_debug_verbose

  include JobHelper

  attr_accessor :email_results_to,
                :hostname,
                :hostnames,
                :job_delay,
                :msg_queue,
                :options,
                :subscription_service_id,
                :timestamp_begin,
                :timestamp_end,
                :verbose

  def default_value_is( value, default_value = nil )
    return value if value.present?
    default_value
  end

  def email_exec_results( exec_str:, rv:, event:, event_note: '' )
    timestamp_end = DateTime.now if timestamp_end.blank?
    ::Deepblue::JobTaskHelper.email_exec_results( targets: email_results_to,
                                                  subscription_service_id: subscription_service_id,
                                                  exec_str: exec_str,
                                                  rv: rv,
                                                  event: event,
                                                  event_note: event_note,
                                                  messages: msg_queue,
                                                  timestamp_begin: timestamp_begin,
                                                  timestamp_end: timestamp_end )
  end

  def email_failure( task_name:, exception:, event:, event_note: '' )
    timestamp_end = DateTime.now if timestamp_end.blank?
    ::Deepblue::JobTaskHelper.email_failure( targets: email_results_to,
                                             subscription_service_id: subscription_service_id,
                                             task_name: task_name,
                                             exception: exception,
                                             event: event,
                                             event_note: event_note,
                                             messages: msg_queue,
                                             timestamp_begin: timestamp_begin,
                                             timestamp_end: timestamp_end )
  end

  def email_results( task_name:, event:, event_note: '' )
    timestamp_end = DateTime.now if timestamp_end.blank?
    ::Deepblue::JobTaskHelper.email_results( targets: email_results_to,
                                             subscription_service_id: subscription_service_id,
                                             task_name: task_name,
                                             event: event,
                                             event_note: event_note,
                                             messages: msg_queue,
                                             timestamp_begin: timestamp_begin,
                                             timestamp_end: timestamp_end )
  end

  def msg_queue
    @msg_queue ||= []
  end

  def initialize_from_args( *args )
    @timestamp_begin = DateTime.now
    @options = {}
    args.each { |key,value| @options[key] = value }
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "timestamp_begin=#{timestamp_begin}",
                                           "options=#{options}",
                                           "" ] if ABSTRACT_RAKE_TASK_JOB_DEBUG_VERBOSE
    @verbose = job_options_value( options,
                                  key: 'verbose',
                                  default_value: default_value_is( verbose, false ) )
    @job_delay = job_options_value( options,
                                  key: 'job_delay',
                                  default_value: default_value_is( job_delay, 0 ),
                                  verbose: verbose )
    ::Deepblue::LoggingHelper.debug "verbose=#{verbose}" if verbose
    @email_results_to = job_options_value( options,
                                           key: 'email_results_to',
                                           default_value: default_value_is( email_results_to, [] ),
                                           verbose: verbose )
    @subscription_service_id = job_options_value( options,
                                                  key: 'subscription_service_id',
                                                  default_value: default_value_is( subscription_service_id ),
                                                  verbose: verbose )
    @hostnames = job_options_value( options,
                                    key: 'hostnames',
                                    default_value: default_value_is( hostnames, [] ),
                                    verbose: verbose )
    return true if hostnames.blank?
    @hostname = ::DeepBlueDocs::Application.config.hostname
    hostnames.include? hostname
  end

  def run_job_delay
    return if job_delay.blank?
    return if 0 >= job_delay
    if verbose
      msg = "sleeping #{job_delay} seconds"
      Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           msg,
                                           "" ] if ABSTRACT_RAKE_TASK_JOB_DEBUG_VERBOSE
      msg_queue << msg
    end
    sleep job_delay
  end

end
