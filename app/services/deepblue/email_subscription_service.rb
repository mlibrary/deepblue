# frozen_string_literal: true

module Deepblue

  module EmailSubscriptionService

    @@_setup_ran = false
    @@_setup_failed = false

    mattr_accessor :email_subscription_service_debug_verbose, default: false

    def self.setup
      return if @@_setup_ran == true
      @@_setup_ran = true
      begin
        yield self
      rescue Exception => e # rubocop:disable Lint/RescueException
        @@_setup_failed = true
      end
    end

    def self.merge_targets_and_subscribers( targets:, subscription_service_id: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "targets=#{targets}",
                                             "subscription_service_id=#{subscription_service_id}",
                                             "" ] if email_subscription_service_debug_verbose
      return Array( targets ) if subscription_service_id.blank?
      subscribers = ::Deepblue::EmailSubscriptionService.subscribers_for( subscription_service_id: subscription_service_id )
      targets = Array( targets ) | subscribers # merge arrays dropping duplicates
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "targets=#{targets}",
                                             "subscription_service_id=#{subscription_service_id}",
                                             "" ] if email_subscription_service_debug_verbose
      return targets
    end

    def self.subscribers_for( subscription_service_id:,
                              include_parameters: false,
                              debug_verbose: email_subscription_service_debug_verbose )

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "subscription_service_id=#{subscription_service_id}",
                                             "include_parameters=#{include_parameters}",
                                             "" ] if debug_verbose
      records = EmailSubscription.where( subscription_name: subscription_service_id )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "records=#{records}",
                                             "" ] if debug_verbose
      return [] if records.empty?
      rv = []
      records.each do |record|
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "record=#{record}",
                                               "record.email=#{record.email}",
                                               "record.user_id=#{record.user_id}",
                                               "record.subscription_parameters=#{record.subscription_parameters}",
                                               "" ] if debug_verbose
        email = if record.email.present?
                  record.email
                elsif record.user_id.present?
                  begin
                    user = User.find( record.user_id )
                    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                           ::Deepblue::LoggingHelper.called_from,
                                                           "user=#{user}",
                                                           "user&.email=#{user&.email}",
                                                           "" ] if debug_verbose
                    user.email
                  rescue Exception => ignore
                    nil
                  end
                else
                  nil
                end
        if include_parameters
          rv << [ email, record.subscription_parameters ]
        else
          rv << email
        end
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "subscription_service_id=#{subscription_service_id}",
                                             "rv=#{rv}",
                                             "" ] if debug_verbose
      return rv
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

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "email_target=#{email_target}",
                                             "" ] if email_subscription_service_debug_verbose
      hostname = ::DeepBlueDocs::Application.config.hostname if hostname.nil?
      # TODO: integrate timestamps
      body = subject if body.blank?
      email = email_target
      email_sent = ::Deepblue::EmailHelper.send_email( to: email,
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

  end

end
