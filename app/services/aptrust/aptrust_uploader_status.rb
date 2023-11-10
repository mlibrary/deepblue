# frozen_string_literal: true

module Aptrust

  class AptrustUploaderStatus

    attr_accessor :status_history
    attr_accessor :status
    attr_accessor :id

    def initialize( id:, status_history: [] )
      @id = id
      @status_history = status_history
    end

    def status
      @status ||= status_init
    end

    def status_init
      return 'Unknown' if status_history.empty?
      return status_history.first[:id]
    end

    def status_done( status: )
      status_history.each { |history| return true if status == history.id }
      return false
    end

    def track( status:, note: nil )
      @status_history ||= []
      if note.blank?
        status_history << { id: id, status: status, timestamp: DateTime.now }
      else
        status_history << { id: id, status: status, timestamp: DateTime.now, note: note }
      end
    end

  end

end
