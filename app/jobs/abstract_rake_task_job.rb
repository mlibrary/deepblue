# frozen_string_literal: true

class AbstractRakeTaskJob < ::Deepblue::DeepblueJob

  mattr_accessor :abstract_rake_task_job_debug_verbose,
                 default: ::Deepblue::JobTaskHelper.abstract_rake_task_job_debug_verbose

  def email_exec_results( exec_str:, rv:, event:, event_note: '', msg_handler: nil )
    timestamp_end = DateTime.now if timestamp_end.blank?
    if msg_handler.present?
      msgs = msg_handler.msg_queue
    else
      msgs = []
    end
    ::Deepblue::JobTaskHelper.email_exec_results( targets: email_targets,
                                                  subscription_service_id: subscription_service_id,
                                                  exec_str: exec_str,
                                                  rv: rv,
                                                  event: event,
                                                  event_note: event_note,
                                                  messages: msgs,
                                                  msg_handler: msg_handler,
                                                  timestamp_begin: timestamp_begin,
                                                  timestamp_end: timestamp_end )
  end

  def event_name
    @event_name ||= task_name.downcase.gsub( / job$/, '' )
  end

  def initialize_from_args( *args, id: nil, debug_verbose: abstract_rake_task_job_debug_verbose )
    debug_verbose = debug_verbose || abstract_rake_task_job_debug_verbose
    initialize_options_from( *args, id: id, debug_verbose: debug_verbose )
    from_dashboard
    job_delay
    @email_results_to = job_options_value( key: 'email_results_to', default_value: [] )
    email_targets_add @email_results_to
    subscription_service_id
    hostname_allowed
  end

  def run_job_delay
    return if job_delay.blank?
    return if 0 >= job_delay
    if verbose
      msg = "sleeping #{job_delay} seconds"
      Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           msg,
                                           "" ] if debug_verbose
      msg_handler.msg msg
    end
    sleep job_delay
  end

  def task_name
    @task_name ||= self.class.name.titlecase
  end

end
