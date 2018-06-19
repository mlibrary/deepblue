# frozen_string_literal: true

module Deepblue

  module EmailHelper

    def self.echo_to_rails_logger
      DeepBlueDocs::Application.config.email_log_echo_to_rails_logger
    end

    def self.notification_email
      Rails.configuration.notification_email
    end

    def self.log( class_name: 'UnknownClass',
                  event: 'unknown',
                  event_note: '',
                  id: 'unknown_id',
                  timestamp: LoggingHelper.timestamp_now,
                  to:,
                  from:,
                  subject:,
                  **key_values )

      added_key_values = { to: to, from: from, subject: subject }
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

    def self.send_email( to:, from:, subject:, body: )
      # TODO: actually send
      # ApplicationMailer.mail( to: to, from: from, subject: subject, body: body )
      Rails.logger.debug ">>>>>>"
      Rails.logger.debug "email_event_notification"
      Rails.logger.debug "to: #{to}\nfrom: #{from}\nsubject: #{subject}\nbody:\n#{body}"
      Rails.logger.debug ">>>>>>"
    end

    def self.user_email
      Rails.configuration.user_email
    end

    def self.user_email_from( current_user, user_signed_in: true )
      return nil unless user_signed_in
      user_email = nil
      unless current_user.nil?
        # Rails.logger.debug "current_user=#{current_user}"
        # Rails.logger.debug "current_user.name=#{current_user.name}"
        # Rails.logger.debug "current_user.email=#{current_user.email}"
        user_email = current_user.email
      end
      user_email
    end

  end

end
