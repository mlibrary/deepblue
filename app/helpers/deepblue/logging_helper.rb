# frozen_string_literal: true

module Deepblue

  module LoggingHelper

    def self.bold_debug( msg = nil, label: nil, key_value_lines: true, lines: 1, &block )
      lines = 1 if lines < 1
      lines.times { Rails.logger.debug ">>>>>>>>>>" }
      Rails.logger.debug label if label.present?
      if msg.respond_to?( :each )
        msg.each do |m|
          if key_value_lines && m.respond_to?( :each_pair )
            m.each_pair { |k, v| Rails.logger.debug "#{k}: #{v}" }
          else
            Rails.logger.debug m
          end
        end
        Rails.logger.debug nil, &block if block_given?
      else
        Rails.logger.debug msg, &block
      end
      lines.times { Rails.logger.debug ">>>>>>>>>>" }
    end

    def self.initialize_key_values( user_email:, event_note:, **added_key_values )
      key_values = { user_email: user_email }
      key_values.merge!( event_note: event_note ) if event_note.present?
      key_values.merge!( added_key_values ) if added_key_values.present?
      key_values
    end

    def self.log( class_name: 'UnknownClass',
                  event: 'unknown',
                  event_note: '',
                  id: 'unknown_id',
                  timestamp: LoggingHelper.timestamp_now,
                  echo_to_rails_logger: true,
                  logger: Rails.logger,
                  **key_values )

      msg = msg_to_log( class_name: class_name,
                        event: event,
                        event_note: event_note,
                        id: id,
                        timestamp: timestamp,
                        **key_values )
      logger.info msg
      Rails.logger.info msg if echo_to_rails_logger
    end

    def self.msg_to_log( class_name:, event:, event_note:, id:, timestamp:, json_encode: true, **added_key_values )
      if event_note.blank?
        key_values = { event: event, timestamp: timestamp, class_name: class_name, id: id }
        event += '/'
      else
        key_values = { event: event, event_note: event_note, timestamp: timestamp, class_name: class_name, id: id }
        event = "#{event}/#{event_note}"
      end
      key_values.merge! added_key_values
      key_values = ActiveSupport::JSON.encode key_values if json_encode
      "#{timestamp} #{event}/#{class_name}/#{id} #{key_values}"
    end

    def self.system_as_current_user
      "Deepblue"
    end

    def self.timestamp_now
      Time.now.to_formatted_s(:db )
    end

    def self.to_log_format_timestamp( timestamp )
      timestamp = Time.parse( timestamp ) if timestamp.is_a? String
      timestamp = timestamp.to_formatted_s( :db ) if timestamp.is_a? Time
      timestamp.to_s
    end

  end

end
