# frozen_string_literal: true

module Deepblue

  class LoggingCallback

    def self.process_event( event_name:, msg: )
      Rails.logger.debug ">>>>> #{event_name} >>>>>"
      Rails.logger.debug ">>>>> #{event_name} >>>>>"
      Rails.logger.debug "#{event_name} >>>>> #{msg}"
      Rails.logger.debug ">>>>> #{event_name} >>>>>"
      Rails.logger.debug ">>>>> #{event_name} >>>>>"
    end

    def self.process_event_curation_concern( event_name:, curation_concern:, user: )
      Rails.logger.debug ">>>>> #{event_name} >>>>>"
      Rails.logger.debug ">>>>> #{event_name} >>>>>"
      Rails.logger.debug "#{event_name} >>>>> #{user} >>>>> #{curation_concern}"
      Rails.logger.debug ">>>>> #{event_name} >>>>>"
      Rails.logger.debug ">>>>> #{event_name} >>>>>"
    end

    def self.process_event_file_set( event_name:, file_set:, user: )
      Rails.logger.debug ">>>>> #{event_name} >>>>>"
      Rails.logger.debug ">>>>> #{event_name} >>>>>"
      Rails.logger.debug "#{event_name} >>>>> #{user} >>>>> #{file_set}"
      Rails.logger.debug ">>>>> #{event_name} >>>>>"
      Rails.logger.debug ">>>>> #{event_name} >>>>>"
    end

    def self.process_event_user( event_name:, user:, msg: '' )
      Rails.logger.debug ">>>>> #{event_name} >>>>>"
      Rails.logger.debug ">>>>> #{event_name} >>>>>"
      Rails.logger.debug "#{event_name} >>>>> #{user}" if msg.blank?
      Rails.logger.debug "#{event_name} >>>>> #{user} >>>>> #{msg}" if msg.present?
      Rails.logger.debug ">>>>> #{event_name} >>>>>"
      Rails.logger.debug ">>>>> #{event_name} >>>>>"
    end

  end

end