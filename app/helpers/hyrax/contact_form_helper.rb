# frozen_string_literal: true

module Hyrax

  require './lib/hyrax/contact_form_logger'

  module ContactFormHelper

    # extend JsonLoggerHelper
    # extend JsonLoggerHelper::ClassMethods

    def self.echo_to_rails_logger
      ContactFormIntegrationService.contact_form_log_echo_to_rails_logger
    end

    def self.log( class_name: 'UnknownClass',
                  event: 'unknown',
                  event_note: '',
                  id: '',
                  timestamp: timestamp_now,
                  echo_to_rails_logger: ContactFormIntegrationService.contact_form_log_echo_to_rails_logger,
                  contact_method:,
                  category:,
                  name:,
                  email:,
                  subject:,
                  message:,
                  **log_key_values )

      log_key_values = log_key_values.merge( contact_method: contact_method,
                                             category: category,
                                             name: name,
                                             email: email,
                                             subject: subject,
                                             message: message )
      msg = msg_to_log( class_name: class_name,
                        event: event,
                        event_note: event_note,
                        id: id,
                        timestamp: timestamp,
                        time_zone: LoggingHelper.timestamp_zone,
                        **log_key_values )
      log_raw msg
      Rails.logger.info msg if echo_to_rails_logger
    end

    def self.log_raw( msg )
      CONTACT_FORM_LOGGER.info( msg )
    end

  end

end
