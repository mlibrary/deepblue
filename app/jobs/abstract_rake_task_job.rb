# frozen_string_literal: true

class AbstractRakeTaskJob < ::Hyrax::ApplicationJob

  mattr_accessor :abstract_rake_task_job_debug_verbose,
                 default: ::Deepblue::JobTaskHelper.abstract_rake_task_job_debug_verbose

  include JobHelper # see JobHelper for :email_targets, :hostname, :job_msg_queue, :timestamp_begin, :timestamp_end

  attr_accessor :hostnames,
                :job_delay,
                :options,
                :subscription_service_id,
                :task,
                :verbose

  def default_value_is( value, default_value = nil )
    return value if value.present?
    default_value
  end

  def email_exec_results( exec_str:, rv:, event:, event_note: '' )
    timestamp_end = DateTime.now if timestamp_end.blank?
    ::Deepblue::JobTaskHelper.email_exec_results( targets: email_targets,
                                                  subscription_service_id: subscription_service_id,
                                                  exec_str: exec_str,
                                                  rv: rv,
                                                  event: event,
                                                  event_note: event_note,
                                                  messages: job_msg_queue,
                                                  timestamp_begin: timestamp_begin,
                                                  timestamp_end: timestamp_end )
  end

  def event_name
    @event_name ||= task_name.downcase.gsub( / job$/, '' )
  end

  def initialize_from_args( *args )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "args=#{args}",
                                           "" ] if abstract_rake_task_job_debug_verbose
    @timestamp_begin = DateTime.now
    @options = {}
    args.each { |key,value| @options[key.to_s] = value }
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "timestamp_begin=#{timestamp_begin}",
                                           "options=#{options}",
                                           "" ] if abstract_rake_task_job_debug_verbose
    @task = job_options_value( options,
                               key: 'task',
                               default_value: default_value_is( task, false ),
                               task: false )
    @verbose = job_options_value( options,
                                  key: 'verbose',
                                  default_value: default_value_is( verbose, false ),
                                  task: task )
    @job_delay = job_options_value( options,
                                    key: 'job_delay',
                                    default_value: default_value_is( job_delay, 0 ),
                                    verbose: verbose,
                                    task: task )
    ::Deepblue::LoggingHelper.debug "verbose=#{verbose}" if verbose
    email_targets << job_options_value( options,
                                        key: 'email_results_to',
                                        default_value: default_value_is( email_targets, [] ),
                                        verbose: verbose,
                                        task: task )
    @subscription_service_id = job_options_value( options,
                                                  key: 'subscription_service_id',
                                                  default_value: default_value_is( subscription_service_id ),
                                                  verbose: verbose,
                                                  task: task )
    @hostnames = job_options_value( options,
                                    key: 'hostnames',
                                    default_value: default_value_is( hostnames, [] ),
                                    verbose: verbose,
                                    task: task )
    return true if hostnames.blank?
    # @hostname = ::DeepBlueDocs::Application.config.hostname
    hostnames.include? hostname
  end

  def options_value( key:, default_value: nil, verbose: self.verbose, task: self.task )
    job_options_value( options, key: key, default_value: default_value, verbose: verbose, task: task )
  end

  def run_job_delay
    return if job_delay.blank?
    return if 0 >= job_delay
    if verbose
      msg = "sleeping #{job_delay} seconds"
      Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           msg,
                                           "" ] if abstract_rake_task_job_debug_verbose
      job_msg_queue << msg
    end
    sleep job_delay
  end

  def task_name
    @task_name ||= self.class.name.titlecase
  end

end
