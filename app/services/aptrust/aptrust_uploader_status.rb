# frozen_string_literal: true

require_relative './aptrust'

module Aptrust

  class AptrustUploaderStatus

    attr_accessor :status_history
    attr_accessor :status
    attr_accessor :id

    def initialize( id:, status_history: nil )
      @id = id
      @status_history = status_history
    end

    def status
      @status ||= status_init
    end

    def status_history
      @status_history ||= status_history_init
    end

    def status_history_init
      rv = if STATUS_IN_DB
             history = []
             records = Event.where( noid: id )
             records.each { |e| history << { id: e.id, status: e.event, note: e.event_note} }
             history
           else
             []
           end
      return rv
    end

    def status_init
      return EVENT_UNKNOWN if status_history.empty?
      return status_history.first[:id]
    end

    def status_done( status: )
      status_history.each { |history| return true if status == history.id }
      return false
    end

    def track( status:, note: nil, timestamp: DateTime.now )
      @status_history ||= []
      timestamp ||= DateTime.now
      if note.blank?
        status_history << { id: id, status: status, timestamp: timestamp }
      else
        status_history << { id: id, status: status, timestamp: timestamp, note: note }
      end
      update_db( status_event: status, note: note, timestamp: timestamp ) if STATUS_IN_DB
    end

    def update_db( status_event:, note: nil, timestamp: DateTime.now )
      timestamp ||= DateTime.now
      noid = id
      status = Status.for_id( noid: noid )
      if status.blank?
        status = Status.new( timestamp: timestamp, event: status_event, event_note: note, noid: noid )
      else
        status.timestamp = timestamp
        status.event = status_event
        status.event_note = event_note
      end
      status.save
      aptrust_status_id = status.id
      event = Event.new( timestamp: timestamp,
                         event: status,
                         event_note: note,
                         noid: noid,
                         aptrust_status_id: aptrust_status_id )
      event.save
    end

    def load_status_history
      status = Status.for_id( noid: noid )
    end

  end

end
