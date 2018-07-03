# frozen_string_literal: true

module Deepblue

  module EmailHelper

    def self.echo_to_rails_logger
      DeepBlueDocs::Application.config.email_log_echo_to_rails_logger
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

    def self.notification_email
      Rails.configuration.notification_email
    end

    def self.send_email( to:, from:, subject:, body: )
      # TODO: actually send
      # email = ApplicationMailer.mail( to: to, from: from, subject: subject, body: body )
      # email.deliver_now
      LoggingHelper.bold_debug [ "email_event_notification", "to: #{to}\nfrom: #{from}\nsubject: #{subject}\nbody:\n#{body}" ]
    end

    def self.send_email_create_work( to: notification_email, from: notification_email, body: '' )
      send_email( to: to, from: from, subject: 'DBD: New Work Created', body: body )
    end

    def self.send_email_deposit_work( to: notification_email, from: notification_email, body: '' )
      send_email( to: to, from: from, subject: 'DBD: New Deposit', body: body )
    end

    def self.send_email_delete_work( to: notification_email, from: notification_email, body: '' )
      send_email( to: to, from: from, subject: 'DBD: Work Deleted', body: body )
    end

    def self.send_email_globus_clean_job_complete( to:, body: )
      send_email( to: to, from: to, subject: 'DBD: Globus Clean Job Complete', body: body )
    end

    def self.send_email_globus_job_complete( to:, body: )
      send_email( to: to, from: to, subject: 'DBD: Globus Work Files Available', body: body )
    end

    def self.send_email_globus_job_started( to: notification_email, body: '' )
      send_email( to: to, from: to, subject: 'DBD: Globus Work Copy Job Started', body: body )
    end

    def self.send_email_globus_push_work( to:, from:, body: )
      send_email( to: to, from: from, subject: 'DBD: Globus Work Files Prepared', body: body )
    end

    def self.send_email_publish_work( to: notification_email, from: notification_email, body: '' )
      send_email( to: to, from: from, subject: 'DBD: Work Published', body: body )
    end

    def self.send_email_update_work( to: notification_email, from: notification_email, body: '' )
      send_email( to: to, from: from, subject: 'DBD: Work Updated', body: body )
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
