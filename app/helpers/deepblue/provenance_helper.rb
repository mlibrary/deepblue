# frozen_string_literal: true

module Deepblue

  class LogParseError < RuntimeError
  end

  module ProvenanceHelper

    TIMESTAMP_FORMAT = '\d\d\d\d\-\d\d\-\d\d \d\d:\d\d:\d\d'
    RE_TIMESTAMP_FORMAT = Regexp.compile "^#{TIMESTAMP_FORMAT}$"
    # Format: Date Timestamp Event/Event_detail_possibly_empty/ClassName/ID_possibly_empty Rest_in_form_of_JSON_hash
    RE_LOG_LINE = Regexp.compile "^(#{TIMESTAMP_FORMAT}) ([^/]+)/([^/]*)/([^/]+)/([^/ ]*) (.*)$"
    PREFIX_UPDATE_ATTRIBUTE = 'UpdateAttribute_'

    # rubocop:disable Style/ClassVars
    def self.echo_to_rails_logger
      @@echo_to_rails_logger ||= DeepBlueDocs::Application.config.provenance_log_echo_to_rails_logger
    end

    def self.echo_to_rails_logger=( echo_to_rails_logger )
      @@echo_to_rails_logger = echo_to_rails_logger
    end
    # rubocop:enable Style/ClassVars

    def self.form_params_to_update_attribute_key_values( curation_concern:,
                                                         form_params:,
                                                         update_key_prefix: PREFIX_UPDATE_ATTRIBUTE,
                                                         delta_only: true )

      attr_key_values = {}
      form_params.each_pair do |key, value|
        update_key = "#{update_key_prefix}#{key}".to_sym
        key = key.to_sym
        next unless curation_concern.has_attribute? key
        if value.is_a? Array
          if value.blank?
            value = nil
          elsif [''] == value
            value = nil
          elsif 1 < value.size
            value.pop if '' == value.last
          end
        end
        old_value = curation_concern[key]
        new_value = nil
        if delta_only
          unless old_value.blank? && value.blank?
            # old_value = ActiveSupport::JSON.encode old_value
            # old_value = ActiveSupport::JSON.decode old_value
            # attr_key_values[update_key] = { key: key, old_value: old_value, new_value: value } unless old_value == value
            new_value = value unless old_value == value
          end
        else
          # old_value = ActiveSupport::JSON.encode old_value
          # old_value = ActiveSupport::JSON.decode old_value
          # attr_key_values[update_key] = { key: key, old_value: old_value, new_value: value }
          new_value = value
        end
        next if new_value.nil?
        # do a deep copy
        old_value = ActiveSupport::JSON.encode old_value
        old_value = ActiveSupport::JSON.decode old_value
        attr_key_values[update_key] = { attribute: key, old_value: old_value, new_value: value }
      end
      attr_key_values
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
      key_values = prov_encode( value: key_values, json_encode: json_encode )
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

    def self.parse_log_line( line, line_number: nil, raw_key_values: false )
      # line is of the form: "timestamp event/event_note/class_name/id key_values"
      match = RE_LOG_LINE.match line
      unless match
        msg = "parse of log line failed: '#{line}'" if line_number.blank?
        msg = "parse of log line failed at line #{line_number}: '#{line}'" if line_number.present?
        raise LogParseError, msg
      end
      timestamp = match[1]
      event = match[2]
      event_note = match[3]
      class_name = match[4]
      id = match[5]
      key_values = match[6]
      key_values = parse_log_line_key_values key_values unless raw_key_values
      return timestamp, event, event_note, class_name, id, key_values
    end

    def self.parse_log_line_key_values( key_values )
      ActiveSupport::JSON.decode key_values
    end

    def self.prov_encode( value:, json_encode: true )
      return value unless json_encode
      begin
        return ActiveSupport::JSON.encode value
      rescue Exception => e # rubocop:disable Lint/RescueException
        Rails.logger.error "#{e.class}: #{e.message} at #{e.backtrace[0]}"
        return value.to_s unless value.respond_to? :each_pair
        new_value = {}
        value.each_pair do |key, val|
          new_value[key] = prov_encode( value: val )
        end
        return ActiveSupport::JSON.encode new_value
      end
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

    def self.update_attribute_key_values( curation_concern:,
                                          update_key_prefix: PREFIX_UPDATE_ATTRIBUTE,
                                          **update_attr_key_values )

      return nil if update_attr_key_values.blank?
      new_update_attr_key_values = {}
      key_values = update_attr_key_values
      key_values = key_values[:update_attr_key_values] if key_values.key?( :update_attr_key_values )
      # puts ActiveSupport::JSON.encode key_values
      key_values.each_pair do |key, value|
        # puts "#{key}:-#{value}"
        next unless key.to_s.start_with? update_key_prefix
        attribute = value[:attribute]
        old_value = value[:old_value]
        new_value = curation_concern[attribute]
        # puts "#{attribute}, #{old_value}, #{new_value}"
        new_update_attr_key_values[key] = { attribute: attribute, old_value: old_value, new_value: new_value } unless old_value == new_value
      end
      return new_update_attr_key_values
    end

  end

end
