# frozen_string_literal: true

module Deepblue

  module ProvenanceHelper

    def self.echo_to_rails_logger
      DeepBlueDocs::Application.config.provenance_log_echo_to_rails_logger
    end

    def self.initialize_prov_key_values( user_email:, event_note:, **added_prov_key_values )
      prov_key_values = { user_email: user_email }
      prov_key_values.merge!( event_note: event_note ) if event_note.present?
      prov_key_values.merge!( added_prov_key_values ) if added_prov_key_values.present?
      prov_key_values
    end

    def self.msg_to_log( class_name:, event:, event_note:, id:, timestamp:, json_encode: true, **prov_key_values )
      if event_note.blank?
        key_values = { event: event, timestamp: timestamp, class_name: class_name, id: id }
        event += '/'
      else
        key_values = { event: event, event_note: event_note, timestamp: timestamp, class_name: class_name, id: id }
        event = "#{event}/#{event_note}"
      end
      key_values.merge! prov_key_values
      key_values = ActiveSupport::JSON.encode key_values if json_encode
      "#{timestamp} #{event}/#{class_name}/#{id} #{key_values}"
    end

    def self.log( class_name: 'UnknownClass',
                  event: 'unknown',
                  event_note: '',
                  id: 'unknown_id',
                  timestamp: timestamp_now,
                  echo_to_rails_logger: ProvenanceHelper.echo_to_rails_logger,
                  **prov_key_values )

      msg = msg_to_log( class_name: class_name,
                        event: event,
                        event_note: event_note,
                        id: id,
                        timestamp: timestamp,
                        **prov_key_values )
      log_raw msg
      Rails.logger.info msg if echo_to_rails_logger
    end

    def self.log_raw( msg )
      PROV_LOGGER.info( msg )
    end

    def self.system_as_current_user
      "Deepblue"
    end

    def self.timestamp_now
      Time.now.to_formatted_s(:db)
    end

    def self.to_log_format_timestamp( timestamp )
      timestamp = Time.parse( timestamp ) if timestamp.is_a? String
      timestamp = timestamp.to_formatted_s( :db ) if timestamp.is_a? Time
      timestamp.to_s
    end

  end

end
