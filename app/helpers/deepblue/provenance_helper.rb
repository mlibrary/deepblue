# frozen_string_literal: true

module Deepblue

  class LogParseError < RuntimeError
  end

  module ProvenanceHelper

    TIMESTAMP_FORMAT = '\d\d\d\d\-\d\d\-\d\d \d\d:\d\d:\d\d'
    RE_TIMESTAMP_FORMAT = Regexp.compile "^#{TIMESTAMP_FORMAT}$"
    RE_LOG_LINE = Regexp.compile "^(#{TIMESTAMP_FORMAT}) ([^/]+)/([^/]*)/([^/]+)/([^/ ]+) (.*)$"

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

    def self.parse_log_line( line )
      # line is of the form: "timestamp event/event_note/class_name/id key_values"
      match = RE_LOG_LINE.match line
      raise LogParseError, "parse of log line failed: '#{line}'" unless match
      timestamp = match[1]
      event = match[2]
      event_note = match[3]
      class_name = match[4]
      id = match[5]
      key_values = match[6]
      key_values = ActiveSupport::JSON.decode key_values
      return timestamp, event, event_note, class_name, id, key_values
    end

    def self.system_as_current_user
      "Deepblue"
    end

    def self.timestamp_now
      Time.now.to_formatted_s(:db )
    end

    def self.to_log_format_timestamp( timestamp )
      is_a_string = timestamp.is_a?( String )
      return timestamp if is_a_string && RE_TIMESTAMP_FORMAT =~ timestamp
      timestamp = Time.parse( timestamp ) if is_a_string
      timestamp = timestamp.to_formatted_s( :db ) if timestamp.is_a? Time
      timestamp.to_s
    end

  end

end
