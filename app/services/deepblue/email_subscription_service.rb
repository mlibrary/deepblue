# frozen_string_literal: true

module Deepblue

  module EmailSubscriptionService

    EMAIL_SUBSCRIPTION_SERVICE_DEBUG_VERBOSE = false

    def self.merge_targets_and_subscribers( targets:, subscription_service_id: )
      return Array( targets ) if subscription_service_id.blank?
      subscribers = ::Deepblue::EmailSubscriptionService.subscribers_for( subscription_service_id: subscription_service_id )
      targets = Array( targets ) | subscribers # merge arrays dropping duplicates
      return targets
    end

    def self.subscription_send_email( email_target:,
                                      content_type: nil,
                                      hostname: nil,
                                      subject:,
                                      body: nil,
                                      event:,
                                      event_note: '',
                                      id: 'NA',
                                      subscription_service_id:,
                                      timestamp_begin: nil,
                                      timestamp_end: DateTime.now  )

      hostname = ::DeepBlueDocs::Application.config.hostname if hostname.nil?
      # TODO: integrate timestamps
      body = subject if body.blank?
      email = email_target
      email_sent = ::Deepblue::EmailHelper.send_email( to: email,
                                                       from: email,
                                                       subject: subject,
                                                       body: body,
                                                       content_type: content_type )
      ::Deepblue::EmailHelper.log( class_name: self.class.name,
                                   current_user: nil,
                                   event: event,
                                   event_note: event_note,
                                   id: id,
                                   to: email,
                                   from: email,
                                   subject: subject,
                                   body: body,
                                   email_sent: email_sent )
    end

    def self.subscribers_for( subscription_service_id: )
      records = EmailSubscription.where( subscription_name: subscription_service_id )
      return [] if records.empty?
      rv = []
      records.each do |record|
        if record.email.present?
          rv << record.email
        elsif record.user_id.present?
          begin
            user = User.find_by( record.user_id )
            rv << user.email
          rescue Exception => ignore
          end
        end
      end
      return rv
    end

  end

end
