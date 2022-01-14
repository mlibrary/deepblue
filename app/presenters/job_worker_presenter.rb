# frozen_string_literal: true

class JobWorkerPresenter

  mattr_accessor :job_worker_debug_verbose, default: false

  attr_accessor :controller, :job

  delegate :current_ability, to: :controller

  def initialize( controller:, job: )
    @controller = controller
    @job = job
  end

  def job_as_keys_table
    return '' unless job.present?
    JsonHelper.key_values_to_table( job, parse: true )
  end

  def arguments
    value = job['arguments']
    return '' unless value.present?
    JsonHelper.key_values_to_table( value, parse: true )
  end

  def executions
    job['executions']
  end

  def job_class
    job['job_class']
  end

  def job_id
    job['job_id']
  end

  def locales
    job['locales']
  end

  def priority
    job['priority']
  end

  def provider_job_id
    job['provider_job_id']
  end

  def queue_name
    job['queue_name']
  end

end
