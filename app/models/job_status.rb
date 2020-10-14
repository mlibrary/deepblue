# frozen_string_literal: true

class JobStatus < ApplicationRecord

  JOB_STATUS_DEBUG_VERBOSE = true

  FINISHED = 'finished'.freeze
  STARTED = 'started'.freeze

  def self.find_or_create( job:, status: nil, message: nil, error: nil, parent_job_id: nil )
    return if job.nil?
    job_id = job.job_id
    job_class_name = job.class.name
    job_status = JobStatus.where( job_id: job_id, job_class: job_class_name ).first_or_create
    if status.present? || message.present? || error.present? || parent_job_id.present?
      job_status.status = status.to_s if status.present?
      job_status.message = message.to_s if message.present?
      job_status.error = error.to_s if error.present?
      job_status.parent_job_id = parent_job_id.to_s if parent_job_id.present?
      job_status.save!
    end
    return job_status
  end

  def self.find_or_create_job_error( job:, error:, parent_job_id: nil )
    return nil if job.nil?
    find_or_create( job: job, error: error, parent_job_id: parent_job_id )
  end

  def self.find_or_create_job_finished( job:, message: nil )
    return nil if job.nil?
    find_or_create( job: job, status: FINISHED, message: message )
  end

  def self.find_or_create_job_started( job:, message: nil, parent_job_id: nil )
    return nil if job.nil?
    find_or_create( job: job, status: STARTED, message: message, parent_job_id: parent_job_id )
  end

  def self.is_finished?( job: nil, job_id: nil )
    job_id = job.job_id if job.present?
    return false unless job_id.present?
    job_status = JobStatus.find_by_job_id( job_id )
    return false unless job_status.present?
    job_status.is_finished?
  end

  def self.status?( job: nil, job_id: nil, status: )
    job_id = job.job_id if job.present?
    return false unless job_id.present?
    job_status = JobStatus.find_by_job_id( job_id )
    return false unless job_status.present?
    job_status.status? status
  end

  def self.update_status( job: nil, job_id: nil, status:, message: nil, error: nil )
    job_id = job.job_id if job.present?
    return nil if job_id.blank?
    job_status = JobStatus.find_by_job_id( job_id )
    return nil if job_status.nil?
    job_status.status = status
    job_status.message = message if message.present?
    job_status.error = error if error.present?
    job_status.save!
    return job_status
  end

  def self.update_status_finished( job: nil, job_id: nil, message: nil, error: nil )
    update_status( job: job, job_id: job_id, status: FINISHED, message: message, error: error )
  end

  def self.update_status_started( job: nil, job_id: nil, message: nil, error: nil )
    update_status( job: job, job_id: job_id, status: STARTED, message: message, error: error )
  end

  def add_error!( error:, sep: "\n" )
    if self.error.blank?
      self.error = error
    else
      self.error = "#{self.error}#{sep}#{error}"
    end
    save!
    return self
  end

  def add_message!( message:, sep: "\n" )
    if self.message.blank?
      self.message = message
    else
      self.message = "#{self.message}#{sep}#{message}"
    end
    save!
    return self
  end

  def is_finished?
    status? FINISHED
  end

  def is_null_job_status?
    false
  end

  def is_started?
    status? STARTED
  end

  def state_deserialize
    if state.blank?
      nil
    else
      ActiveSupport::JSON.decode state
    end
  rescue ActiveSupport::JSON.parse_error # rubocop:disable Lint/HandleExceptions
    nil # TODO
  end

  def state_serialize( state )
    if state.blank?
      self.state = nil
    else
      self.state = ActiveSupport::JSON.encode( state ).to_s
    end
  rescue ActiveSupport::JSON.parse_error # rubocop:disable Lint/HandleExceptions
    # TODO
  end

  def status?( status )
    status == self.status
  end

  def update_error!( error: nil )
    self.error = error.to_s
    save!
    return self
  end

  def update_finished!( message: nil )
    update_status!( status: FINISHED, message: message )
  end

  def update_started!( message: nil )
    update_status!( status: STARTED, message: message )
  end

  def update_status!( status:, message: nil, error: nil )
    self.status = status
    self.message = message.to_s if message.present?
    self.error = error.to_s if error.present?
    save!
    return self
  end

end

class NullJobStatus

  ID = 'nil'

  def self.instance
    @@instance || NullJobStatus.new
  end

  def initialize
    # nothing to do
  end

  def error
    nil
  end

  def job_class
    nil
  end

  def job_id
    ID
  end

  def message
    nil
  end

  def parent_job_id
    nil
  end

  def state
    nil
  end

  def status
    nil
  end

  def add_error!( _error:, _sep: "\n" )
    # ignore
    return self
  end

  def add_message!( _message:, _sep: "\n" )
    # ignore
    return self
  end

  def is_finished?
    false
  end

  def is_null_job_status?
    true
  end

  def is_started?
    false
  end

  def save!
    # ignore
  end

  def state_deserialize
    nil
  end

  def state_serialize( _state )
    # ignore
  end

  def status?( _status )
    false
  end

  def update_error!( _error: nil )
    # ignore
    return self
  end

  def update_finished!( _message: nil )
    # ignore
    return self
  end

  def update_started!( _message: nil )
    # ignore
    return self
  end

  def update_status!( _status:, _message: nil, _error: nil )
    # ignore
    return self
  end

end

