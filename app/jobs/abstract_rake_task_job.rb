# frozen_string_literal: true

class AbstractRakeTaskJob < ::Hyrax::ApplicationJob

  mattr_accessor :abstract_rake_task_job_debug_verbose,
                 default: ::Deepblue::JobTaskHelper.abstract_rake_task_job_debug_verbose

  include JobHelper
  # see JobHelper for :by_request_only, :email_targets, :hostname, :job_msg_queue, :timestamp_begin, :timestamp_end

  attr_accessor :debug_verbose
  attr_accessor :from_dashboard
  attr_accessor :hostnames
  attr_accessor :is_quiet
  attr_accessor :job_delay
  attr_accessor :msg_handler
  attr_accessor :options
  attr_accessor :subscription_service_id
  attr_accessor :task
  attr_accessor :verbose

  def debug_verbose
    @debug_verbose ||= abstract_rake_task_job_debug_verbose
  end
  alias :debug_verbose? :debug_verbose

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

  alias :from_dashboard? :from_dashboard

  def initialize_from_args( *args )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "args=#{args}",
                                           "" ] if debug_verbose
    @timestamp_begin = DateTime.now
    @options = {}
    args.each { |key,value| @options[key.to_s] = value }
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "timestamp_begin=#{timestamp_begin}",
                                           "options=#{options}",
                                           "" ] if debug_verbose
    @task            = init_from_arg( arg: 'task', default_var: task, default_value: false, task: false, verbose: false )
    @verbose         = init_from_arg( arg: 'verbose', default_var: verbose, default_value: false, verbose: false )
    ::Deepblue::LoggingHelper.debug "verbose=#{verbose}" if verbose
    @by_request_only = init_from_arg( arg: 'by_request_only', default_var: by_request_only, default_value: false )
    @from_dashboard  = init_from_arg( arg: 'from_dashboard', default_var: from_dashboard, default_value: '' )
    return false if from_dashboard.present? && by_request_only?

    @is_quiet        = init_from_arg( arg: 'is_quiet',       default_var: is_quiet,       default_value: false )
    @job_delay       = init_from_arg( arg: 'job_delay',      default_var: job_delay,      default_value: 0 )
    email_targets_add init_from_arg( arg: 'email_results_to', default_var: email_targets, default_value: [] )
    @subscription_service_id = init_from_arg( arg: 'subscription_service_id', default_var: subscription_service_id, default_value: nil )
    @hostnames = init_from_arg( arg: 'hostnames', default_var: hostnames, default_value: [] )
    return true if hostnames.blank?
    # @hostname = Rails.configuration.hostname
    hostnames.include? hostname
  end

  def init_from_arg( arg:, default_var: nil, default_value: nil, task: @task, verbose: @verbose )
    super( arg: arg, default_var: default_var, default_value: default_value, task: task, verbose: verbose )
  end

  def msg_handler
    @msg_handler ||= ::Deepblue::MessageHandler.new( debug_verbose: debug_verbose,
                                                     msg_queue: job_msg_queue,
                                                     to_console: task,
                                                     verbose: verbose )
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
                                           "" ] if debug_verbose
      job_msg_queue << msg
    end
    sleep job_delay
  end

  def task_name
    @task_name ||= self.class.name.titlecase
  end

end
