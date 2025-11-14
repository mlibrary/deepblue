# frozen_string_literal: true

class JobStatus < ApplicationRecord

  # TODO: make sure message and error columns don't have any odd characters

  # class CreateJobStatuses < ActiveRecord::Migration[5.2]
  #   def change
  #     create_table :job_statuses do |t|
  #       t.string :job_class, null: false
  #       t.string :job_id, null: false
  #       t.string :parent_job_id
  #       t.string :status
  #       t.text :state
  #       t.text :message
  #       t.text :error
  #       t.string :main_cc_id
  #       t.integer :user_id
  #
  #       t.timestamps
  #     end
  #
  #     add_index :job_statuses, :job_id
  #     add_index :job_statuses, :parent_job_id
  #     add_index :job_statuses, :status
  #     add_index :job_statuses, :main_cc_id
  #     add_index :job_statuses, :user_id
  #   end
  # end

  mattr_accessor :job_status_debug_verbose, default: false

  FINISHED = 'finished'.freeze
  STARTED = 'started'.freeze

  def self.clean( str )
    return str unless str.present?
    str = str.to_s unless str.is_a?( String )
    DeepblueHelper.clean_str( str )
  end

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
                                           "" ] if job_status_debug_verbose
    return nil if job.nil?
    job_id = job.job_id
    job_class = job.class.name
    job_status = JobStatus.where( job_id: job_id, job_class: job_class ).first_or_create
    if status.present? || message.present? || error.present? || parent_job_id.present? || main_cc_id.present? || user_id.present?
      job_status.status = status.to_s if status.present?
      job_status.message = clean( message )
      job_status.error = clean( error )
      job_status.parent_job_id = parent_job_id.to_s if parent_job_id.present?
      job_status.main_cc_id = main_cc_id if main_cc_id.present?
      job_status.user_id = user_id if user_id.present?
      job_status.save_safe
    end
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "job.job_id=#{job.job_id}",
                                           "job_status=#{job_status}",
                                           "" ] if job_status_debug_verbose
    return job_status
  end

  def self.find_or_create_job_error( job:, error:, parent_job_id: nil )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "job.nil?=#{job.nil?}",
                                           "job&.job_id=#{job&.job_id}",
                                           "error=#{error}",
                                           "parent_job_id=#{parent_job_id}",
                                           "" ] if job_status_debug_verbose
    return nil if job.nil?
    find_or_create( job: job, error: error, parent_job_id: parent_job_id )
  end

  def self.find_or_create_job_finished( job:, message: nil )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "job.nil?=#{job.nil?}",
                                           "job&.job_id=#{job&.job_id}",
                                           "message=#{message}",
                                           "" ] if job_status_debug_verbose
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
                                           "" ] if job_status_debug_verbose
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
                                           "" ] if job_status_debug_verbose
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
                                           "" ] if job_status_debug_verbose
    job_id = job.job_id if job.present?
    return nil if job_id.blank?
    job_status = JobStatus.find_by_job_id( job_id )
    return nil if job_status.nil?
    job_status.status = status
    job_status.message = clean( message )
    job_status.error = clean( error )
    job_status.save_safe
    return job_status
  end

  def self.update_status_finished( job: nil, job_id: nil, message: nil, error: nil )
    update_status( job: job, job_id: job_id, status: FINISHED, message: message, error: error )
  end

  def self.update_status_started( job: nil, job_id: nil, message: nil, error: nil )
    update_status( job: job, job_id: job_id, status: STARTED, message: message, error: error )
  end

  def add_error( error, sep: "\n" )
    error = clean( error )
    if self.error.blank?
      self.error = error
    else
      self.error = "#{self.error}#{sep}#{error}"
    end
    return self
  end

  def add_error!( error, sep: "\n" )
    # # TODO: virus_scan fix this
    # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
    #                                        ::Deepblue::LoggingHelper.called_from,
    #                                        "error=#{error}" ] + caller_locations(1,40)
    add_error( error, sep: sep )
    save_safe
    return self
  end

  def add_message( msg, sep: "\n" )
    msg = clean( msg )
    msg = "#{self.message}#{sep}#{msg}" if self.message.present?
    self.message =  msg
    return self
  end

  def add_message!( msg, sep: "\n" )
    add_message( msg, sep: sep )
    save_safe
    return self
  end

  def add_messages( messages, sep: "\n" )
    return if messages.blank?
    messages.each { |m| add_message( m, sep: sep ) }
  end

  def add_messages!( messages, sep: "\n" )
    add_messages( messages, sep: sep )
    save_safe
  end

  def clean( str )
    return str unless str.present?
    str = str.to_s unless str.is_a?( String )
    DeepblueHelper.clean_str( str )
  end

  def error!( error: nil )
    self.error = clean( error )
    save_safe
    return self
  end

  def error_snipped
    snipped error
  end

  def messages_snipped
    snipped message
  end

  def save!
    super
  end

  def state_snipped
    snipped state
  end

  def snipped( text )
    return '' if text.blank?
    return text if 24 > text.length
    str = text.gsub( '\n', ' ' )
    # str[9..-1] doesn't work
    sz = str.length
    x = sz - 10
    "#{str[0..9]}...#{str[x..sz]}"
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

  def save_safe
    # TODO: find out a way to directly test the size of the 'message' column
    # TODO: in the mean time, force truncate the message
    begin
      save!
    rescue => e
      raise unless e.message.include? "Data too long for column 'message'"
      save_safe_retry
    end
  end

  def save_safe_retry
    retries = 0
    while ( retries < 4 )
      msg = self.message
      len = msg.length / 2
      self.message = "[#{msg.length}/2]#{msg[0,len]}[...]"
      retries += 1
      begin
        save!
      rescue => e
        raise unless e.message.include? "Data too long for column 'message'"
      end
    end
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
    save_safe
  end

  def status!( status, message: nil, error: nil )
    self.status = status
    self.message = clean( message )
    self.error = clean( error )
    save_safe
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
    #                                        "" ] if job_status_debug_verbose
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

    def save_safe
      # ignore
    end

    def save_safe_retry
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
