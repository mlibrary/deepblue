# frozen_string_literal: true

class JobStatus < ApplicationRecord

  JOB_STATUS_DEBUG_VERBOSE = true

  FINISHED = 'finished'.freeze
  STARTED = 'started'.freeze

  def self.find_or_create( job:,
                           status: nil,
                           message: nil,
                           error: nil,
                           parent_job_id: nil,
                           main_cc_id: nil,
                           user_id: nil )

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "job.nil?=#{job.nil?}",
                                           "job&.job_id=#{job&.job_id}",
                                           "status=#{status}",
                                           "message=#{message}",
                                           "error=#{error}",
                                           "parent_job_id=#{parent_job_id}",
                                           "main_cc_id=#{main_cc_id}",
                                           "user_id=#{user_id}",
                                           "" ] if JOB_STATUS_DEBUG_VERBOSE
    return nil if job.nil?
    job_id = job.job_id
    job_class = job.class.name
    job_status = JobStatus.where( job_id: job_id, job_class: job_class ).first_or_create
    if status.present? || message.present? || error.present? || parent_job_id.present? || main_cc_id.present? || user_id.present?
      job_status.status = status.to_s if status.present?
      job_status.message = message.to_s if message.present?
      job_status.error = error.to_s if error.present?
      job_status.parent_job_id = parent_job_id.to_s if parent_job_id.present?
      job_status.main_cc_id = main_cc_id if main_cc_id.present?
      job_status.user_id = user_id if user_id.present?
      job_status.save!
    end
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "job.job_id=#{job.job_id}",
                                           "job_status=#{job_status}",
                                           "" ] if JOB_STATUS_DEBUG_VERBOSE
    return job_status
  end

  def self.find_or_create_job_error( job:, error:, parent_job_id: nil )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "job.nil?=#{job.nil?}",
                                           "job&.job_id=#{job&.job_id}",
                                           "error=#{error}",
                                           "parent_job_id=#{parent_job_id}",
                                           "" ] if JOB_STATUS_DEBUG_VERBOSE
    return nil if job.nil?
    find_or_create( job: job, error: error, parent_job_id: parent_job_id )
  end

  def self.find_or_create_job_finished( job:, message: nil )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "job.nil?=#{job.nil?}",
                                           "job&.job_id=#{job&.job_id}",
                                           "message=#{message}",
                                           "" ] if JOB_STATUS_DEBUG_VERBOSE
    return nil if job.nil?
    find_or_create( job: job, status: FINISHED, message: message )
  end

  def self.find_or_create_job_started( job:, message: nil, parent_job_id: nil, main_cc_id: nil, user_id: nil )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "job.nil?=#{job.nil?}",
                                           "job&.job_id=#{job&.job_id}",
                                           "message=#{message}",
                                           "parent_job_id=#{parent_job_id}",
                                           "main_cc_id=#{main_cc_id}",
                                           "user_id=#{user_id}",
                                           "" ] if JOB_STATUS_DEBUG_VERBOSE
    return nil if job.nil?
    find_or_create( job: job,
                    status: STARTED,
                    message: message,
                    parent_job_id: parent_job_id,
                    main_cc_id: main_cc_id,
                    user_id: user_id )
  end

  def self.finished?( job: nil, job_id: nil )
    job_id = job.job_id if job.present?
    return false unless job_id.present?
    job_status = JobStatus.find_by_job_id( job_id )
    return false unless job_status.present?
    job_status.finished?
  end

  def self.status?( job: nil, job_id: nil, status: )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "job.nil?=#{job.nil?}",
                                           "job&.job_id=#{job&.job_id}",
                                           "status=#{status}",
                                           "" ] if JOB_STATUS_DEBUG_VERBOSE
    job_id = job.job_id if job.present?
    return false unless job_id.present?
    job_status = JobStatus.find_by_job_id( job_id )
    return false unless job_status.present?
    job_status.status? status
  end

  def self.update_status( job: nil, job_id: nil, status:, message: nil, error: nil )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "job.nil?=#{job.nil?}",
                                           "job&.id=#{job&.id}",
                                           "job_id=#{job_id}",
                                           "status=#{status}",
                                           "message=#{message}",
                                           "error=#{error}",
                                           "" ] if JOB_STATUS_DEBUG_VERBOSE
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

  def add_error( error, sep: "\n" )
    if self.error.blank?
      self.error = error
    else
      self.error = "#{self.error}#{sep}#{error}"
    end
    return self
  end

  def add_error!( error, sep: "\n" )
    add_error( error, sep: sep )
    save!
    return self
  end

  def add_message( message, sep: "\n" )
    if self.message.blank?
      self.message = message
    else
      self.message = "#{self.message}#{sep}#{message}"
    end
    return self
  end

  def add_message!( message, sep: "\n" )
    add_message( message, sep: sep )
    save!
    return self
  end

  def error!( error: nil )
    self.error = error.to_s
    save!
    return self
  end

  def finished!( message: nil )
    status!( FINISHED, message: message )
  end

  def finished?
    status? FINISHED
  end

  def null_job_status?
    false
  end

  def started!( message: nil )
    status!( STARTED, message: message )
  end

  def started?
    status? STARTED
  end

  def state_deserialize
    if state.blank?
      nil
    else
      deserialized_state = ActiveSupport::JSON.decode state
      return deserialized_state
    end
  rescue ActiveSupport::JSON.parse_error # rubocop:disable Lint/HandleExceptions
    nil # TODO
  end

  def state_serialize( state )
    if state.blank?
      self.state = nil
    else
      # TODO: enforce state is a Hash?
      self.state = ActiveSupport::JSON.encode( state ).to_s
    end
  rescue ActiveSupport::JSON.parse_error # rubocop:disable Lint/HandleExceptions
    # TODO
  end

  def state_serialize!( state )
    state_serialize( state )
    save!
  end

  def status!( status, message: nil, error: nil )
    self.status = status
    self.message = message.to_s if message.present?
    self.error = error.to_s if error.present?
    save!
    return self
  end

  def status?( status )
    # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
    #                                        ::Deepblue::LoggingHelper.called_from,
    #                                        "job_id=#{job_id}",
    #                                        "job_class=#{job_class}",
    #                                        "self.status=#{self.status}",
    #                                        "status=#{status}",
    #                                        "status == self.status=#{status == self.status}",
    #                                        "" ] if JOB_STATUS_DEBUG_VERBOSE
    status == self.status
  end

  class Null

    ID = nil # 'nil'

    def self.instance
      @@instance ||= ::JobStatus::Null.new
    end

    def job_class
      nil
    end

    def job_class=(_x)
      # ignore
    end

    def job_id
      nil
    end

    def job_id=(_x)
      # ignore
    end

    def parent_job_id
      nil
    end

    def parent_job_id=(_x)
      # ignore
    end

    def status
      nil
    end

    def status=(_x)
      # ignore
    end

    def state
      nil
    end

    def state=(_x)
      # ignore
    end

    def message
      nil
    end

    def message=(_x)
      # ignore
    end

    def error
      nil
    end

    def error=(_x)
      # ignore
    end

    def main_cc_id
      nil
    end

    def main_cc_id=(_x)
      # ignore
    end

    def user_id
      nil
    end

    def user_id=(_x)
      # ignore
    end

    def initialize
      # nothing to do
    end

    def add_error( _error, sep: "\n" )
      # ignore
      return self
    end

    def add_error!( _error, sep: "\n" )
      # ignore
      return self
    end

    def add_message( _message, sep: "\n" )
      # ignore
      return self
    end

    def add_message!( _message, sep: "\n" )
      # ignore
      return self
    end

    def error!( error: nil )
      # ignore
      return self
    end

    def finished!( message: nil )
      # ignore
      return self
    end

    def finished?
      false
    end

    def null_job_status?
      true
    end

    def reload
      # ignore
    end

    def save!
      # ignore
    end

    def started!( message: nil )
      # ignore
      return self
    end

    def started?
      false
    end

    def state_deserialize
      nil
    end

    def state_serialize( _state )
      # ignore
    end

    def state_serialize!( _state )
      # ignore
    end

    def status!( _status, message: nil, error: nil )
      # ignore
      return self
    end

    def status?( _status )
      false
    end

  end

end
