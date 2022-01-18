# frozen_string_literal: true

class JobWorkerPresenter

  mattr_accessor :job_worker_presenter_debug_verbose, default: false

  attr_accessor :controller, :job

  delegate :current_ability, to: :controller

  def initialize( controller:, job: )
    @controller = controller
    @job = job
  end

  def job_as_keys_table
    return '' unless job.present?
    JsonHelper.key_values_to_table( @job, parse: true )
  end

  def executions
    payload_args['executions'].to_s
  end

  def job_args
    value = payload_args
    return '' unless value.present?
    return value
  end

  def job_args_as_table
    value = job_args
    return '' if value.blank?
    JsonHelper.key_values_to_table( job_args, parse: true )
  end

  def job_class
    payload_args['job_class'].to_s
  end

  def job_id
    payload_args['job_id'].to_s
  end

  def locales
    payload_args['locales'].to_s
  end

  def payload
    rv = job['payload']
    return {} if rv.nil?
    return rv
  end

  def payload_class
    rv = payload['class']
    return '' if rv.nil?
    return rv
  end

  def payload_args
    @payload_args ||= init_payload_args
  end

  def priority
    payload_args['priority'].to_s
  end

  def provider_job_id
    payload_args['provider_job_id'].to_s
  end

  def queue
    rv = job['queue']
    return '' if rv.nil?
    return rv
  end

  def queue_name
    payload_args['queue_name']
  end

  def run_at
    rv = job['run_at']
    return '' if rv.nil?
    return rv
  end

  private

  def init_payload_args
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "payload.class.name=#{payload.class.name}",
                                           "payload=#{payload}",
                                           "" ] if job_worker_presenter_debug_verbose
    rv = payload['args']
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "payload['args'].class.name=#{rv.class.name}",
                                           "payload['args']=#{rv}",
                                           "" ] if job_worker_presenter_debug_verbose
    return {} if rv.blank?
    return {} unless rv.is_a? Array
    # rv = JSON.parse( rv ) unless rv.is_a? Hash
    rv = rv[0]
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "rv.class.name=#{rv.class.name}",
                                           "rv=#{rv}",
                                           "" ] if job_worker_presenter_debug_verbose
    return rv
  end

end
