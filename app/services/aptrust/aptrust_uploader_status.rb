# frozen_string_literal: true

require_relative './aptrust'

class Aptrust::AptrustUploaderStatus

  NOTE_MAX_SIZE = 120 unless const_defined? :NOTE_MAX_SIZE

  mattr_accessor :aptrust_uplaoder_status_debug_verbose, default: false

  def self.clean_database!
    if Rails.env.production?
      ::Aptrust::Event.delete_all
      #ActiveRecord::Base.connection.reset_pk_sequence!(:aptrust_events)
      #ActiveRecord::Base.connection.reset_sequence!(:aptrust_events)
      ::Aptrust::Status.delete_all
      #ActiveRecord::Base.connection.reset_pk_sequence!(:aptrust_statuses)
      #ActiveRecord::Base.connection.reset_sequence!(:aptrust_statuses)
    else
      ActiveRecord::Base.connection.truncate(:aptrust_events)
      ActiveRecord::Base.connection.truncate(:aptrust_statuses)
    end
  end

  def self.clear_history( id: )
    # select all events, then delete
    records = ::Aptrust::Event.where( noid: id )
    records.each { |r| r.delete }
    clear_status( id: id )
  end

  def self.track_db( noid:, status_event:, note: nil, timestamp: DateTime.now )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "noid=#{noid}",
                                           "status_event=#{status_event}",
                                           "note=#{note}",
                                           "timestamp=#{timestamp}",
                                           "" ] if aptrust_uplaoder_status_debug_verbose
    begin
      timestamp ||= DateTime.now
      note = note[0..(NOTE_MAX_SIZE-1)] if !note.nil? && note.size > NOTE_MAX_SIZE
      status = ::Aptrust::Status.for_id( noid: noid )
      if status.blank?
        status = ::Aptrust::Status.new( timestamp: timestamp, event: status_event, event_note: note, noid: noid )
      else
        status = status[0]
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "status=#{status.pretty_inspect}",
                                               "" ] if aptrust_uplaoder_status_debug_verbose
        status.timestamp = timestamp
        status.event = status_event
        status.event_note = note
      end
      status.save
      event = ::Aptrust::Event.new( timestamp: timestamp,
                                    event: status_event,
                                    event_note: note,
                                    noid: noid,
                                    aptrust_status_id: status.id )
      event.save
    rescue Exception => e
      ::Deepblue::LoggingHelper.bold_error ["AptrustUploaderStatus.track_db error #{e}"] + e.backtrace[0..20]
    end
  end

  attr_accessor :id
  attr_accessor :status
  attr_accessor :status_history
  attr_accessor :track_status

  def initialize( id:, status_history: nil, track_status: true )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "id=#{id}",
                                           "status_history=#{status_history}",
                                           "track_status=#{track_status}",
                                           "" ] if aptrust_uplaoder_status_debug_verbose
    @id = id
    @status_history = status_history
    @track_status = track_status && ::Aptrust::STATUS_IN_DB
  end

  def clear_statuses
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "id=#{id}",
                                           "" ] if aptrust_uplaoder_status_debug_verbose
    if @track_status
      records = ::Aptrust::Status.where( noid: id )
      records.each { |r| r.delete }
    end
    @status = ::Aptrust::EVENT_UNKNOWN
    @status_history = []
  end

  def status
    @status ||= status_init
  end

  def status_current
    if @track_status
      records = ::Aptrust::Status.where( noid: id )
      return records.first.event if records.exists?
    end
    if status_history.empty?
      ::Aptrust::EVENT_UNKNOWN
    else
      status_history.last[:status]
    end
  end

  def status_history
    @status_history ||= status_history_init
  end

  def status_history_init
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if aptrust_uplaoder_status_debug_verbose
    rv = if @track_status
           history = []
           records = ::Aptrust::Event.where( noid: id )
           records.each { |e| history << { id: e.id, status: e.event, note: e.event_note } }
           history
         else
           []
         end
    return rv
  end

  def status_init
    if @track_status
      records = ::Aptrust::Status.where( noid: id )
      return records.first.event if records.exists?
    end
    if status_history.empty?
      ::Aptrust::EVENT_UNKNOWN
    else
      status_history.last[:status]
    end
  end

  def status_done( status: )
    status_history.each { |history| return true if status == history.id }
    return false
  end

  def track( status:, note: nil, timestamp: DateTime.now )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "status=#{status}",
                                           "note=#{note}",
                                           "timestamp=#{timestamp}",
                                           "" ] if aptrust_uplaoder_status_debug_verbose
    @status_history ||= []
    timestamp ||= DateTime.now
    if note.blank?
      status_history << { id: id, status: status, timestamp: timestamp }
    else
      status_history << { id: id, status: status, timestamp: timestamp, note: note }
    end
    update_db( status_event: status, note: note, timestamp: timestamp ) if @track_status
  end

  def update_db( status_event:, note: nil, timestamp: DateTime.now )
    ::Aptrust::AptrustUploaderStatus.track_db( noid: id, status_event: status_event, note: note, timestamp: timestamp )
  end

  def load_status_history
    status = ::Aptrust::Status.for_id( noid: id )
  end

end
