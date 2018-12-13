# frozen_string_literal: true

module Deepblue

  module EmailHelper

    def self.contact_email
      Settings.contact_email
    end

    def self.echo_to_rails_logger
      DeepBlueDocs::Application.config.email_log_echo_to_rails_logger
    end

    def self.log( class_name: 'UnknownClass',
                  event: 'unknown',
                  event_note: '',
                  id: 'unknown_id',
                  timestamp: LoggingHelper.timestamp_now,
                  to:,
                  to_note: '',
                  from:,
                  subject:,
                  **key_values )

      email_enabled = DeepBlueDocs::Application.config.email_enabled
      added_key_values = if to_note.blank?
                           { to: to, from: from, subject: subject, email_enabled: email_enabled }
                         else
                           { to: to, to_note: to_note, from: from, subject: subject, email_enabled: email_enabled }
                         end
      key_values.merge! added_key_values
      LoggingHelper.log( class_name: class_name,
                         event: event,
                         event_note: event_note,
                         id: id,
                         timestamp: timestamp,
                         echo_to_rails_logger: EmailHelper.echo_to_rails_logger,
                         logger: EMAIL_LOGGER,
                         **key_values )
    end

    def self.log_raw( msg )
      EMAIL_LOGGER.info( msg )
    end

    def self.notification_email
      Rails.configuration.notification_email
    end

    def self.send_email( to:, from:, subject:, body:, log: false )
      email_enabled = DeepBlueDocs::Application.config.email_enabled
      is_enabled = email_enabled ? "is enabled" : "is not enabled"
      LoggingHelper.bold_debug [ "EmailHelper.send_email #{is_enabled}", "to: #{to} from: #{from} subject: #{subject}\nbody:\n#{body}" ] if log
      return if to.blank?
      return unless email_enabled
      email = DeepblueMailer.send_an_email( to: to, from: from, subject: subject, body: body )
      email.deliver_now
    end

    def self.user_email
      Rails.configuration.user_email
    end

    def self.user_email_from( current_user, user_signed_in: true )
      return nil unless user_signed_in
      user_email = nil
      unless current_user.nil?
        # LoggingHelper.debug "current_user=#{current_user}"
        # LoggingHelper.debug "current_user.name=#{current_user.name}"
        # LoggingHelper.debug "current_user.email=#{current_user.email}"
        user_email = current_user.email
      end
      user_email
    end

  end

end
