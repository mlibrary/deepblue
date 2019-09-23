# frozen_string_literal: true

module Deepblue

  class LogParseError < RuntimeError
  end

  module JsonLoggerHelper

    TIMESTAMP_FORMAT = '\d\d\d\d\-\d\d\-\d\d \d\d:\d\d:\d\d'.freeze
    RE_TIMESTAMP_FORMAT = Regexp.compile "^#{TIMESTAMP_FORMAT}$".freeze
    # Format: Date Timestamp Event/Event_detail_possibly_empty/ClassName/ID_possibly_empty Rest_in_form_of_JSON_hash
    RE_LOG_LINE = Regexp.compile "^(#{TIMESTAMP_FORMAT}) ([^/]+)/([^/]*)/([^/]+)/([^/ ]*) (.*)$".freeze
    PREFIX_UPDATE_ATTRIBUTE = 'UpdateAttribute_'.freeze

    module ClassMethods

      def extract_embargo_form_values( curation_concern:, update_key_prefix:, form_params: )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               ::Deepblue::LoggingHelper.obj_class( "curation_concern", curation_concern ),
                                               "curation_concern.id=#{curation_concern.id}",
                                               "update_key_prefix=#{update_key_prefix}",
                                               "form_params=#{form_params}",
                                               "" ]
        embargo_values = {}
        key = "embargo_release_date"
        new_value = form_params[key]
        old_value = curation_concern.embargo_release_date if curation_concern.respond_to? :embargo_release_date
        update_key = "#{update_key_prefix}#{key}".to_sym
        embargo_values[update_key] = form_update_attribute( key: :embargo_release_date,
                                                            old_value: old_value,
                                                            new_value: new_value )

        key = "visibility_during_embargo"
        new_value = form_params[key]
        old_value = curation_concern.visibility_during_embargo if curation_concern.respond_to? :visibility_during_embargo
        update_key = "#{update_key_prefix}#{key}".to_sym
        embargo_values[update_key] = form_update_attribute( key: :visibility_during_embargo,
                                                            old_value: old_value,
                                                            new_value: new_value )

        key = "visibility_after_embargo"
        new_value = form_params[key]
        old_value = curation_concern.visibility_after_embargo if curation_concern.respond_to? :visibility_after_embargo
        update_key = "#{update_key_prefix}#{key}".to_sym
        embargo_values[update_key] = form_update_attribute( key: :visibility_after_embargo,
                                                            old_value: old_value,
                                                            new_value: new_value )

        embargo_values
      end

      def form_update_attribute( key:, old_value:, new_value: )
        old_value = ActiveSupport::JSON.encode old_value
        old_value = ActiveSupport::JSON.decode old_value
        attr = { attribute: key, old_value: old_value, new_value: new_value }
        attr
      end

      def form_params_to_update_attribute_key_values( curation_concern:,
                                                      form_params:,
                                                      update_key_prefix: PREFIX_UPDATE_ATTRIBUTE,
                                                      delta_only: true )

        attr_key_values = {}
        return attr_key_values if form_params.nil?
        embargo_values = nil
        form_params.each_pair do |key, value|
          update_key = "#{update_key_prefix}#{key}".to_sym
          key = key.to_sym
          has_old_value = case key
                          when :visibility
                            old_value = curation_concern.visibility
                            embargo_values = extract_embargo_form_values( curation_concern: curation_concern,
                                                                          update_key_prefix: update_key_prefix,
                                                                          form_params: form_params ) if value == "embargo"
                            true
                          else
                            if curation_concern.has_attribute? key
                              old_value = curation_concern[key]
                              true
                            else
                              false
                            end
                          end
          next unless has_old_value
          if value.is_a? Array
            if value.blank?
              value = nil
            elsif [''] == value
              value = nil
            elsif 1 < value.size
              value.pop if '' == value.last
            end
          end
          # old_value = curation_concern[key]
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
          attr_key_values[update_key] = form_update_attribute( key: key, old_value: old_value, new_value: value )
        end
        attr_key_values[:embargo] = embargo_values if embargo_values.present?
        attr_key_values
      end

      def logger_initialize_key_values( user_email:, event_note:, **added_key_values )
        key_values = { user_email: user_email }
        key_values.merge!( event_note: event_note ) if event_note.present?
        key_values.merge!( added_key_values ) if added_key_values.present?
        key_values
      end

      def logger_json_encode( value:, json_encode: true )
        return value unless json_encode
        begin
          return ActiveSupport::JSON.encode value
        rescue Exception => e # rubocop:disable Lint/RescueException
          Rails.logger.error "#{e.class}: #{e.message} at #{e.backtrace[0]}"
          return value.to_s unless value.respond_to? :each_pair
          new_value = {}
          value.each_pair do |key, val|
            new_value[key] = logger_json_encode( value: val )
          end
          return ActiveSupport::JSON.encode new_value
        end
      end

      def msg_to_log( class_name:,
                      event:,
                      event_note:,
                      id:,
                      timestamp:,
                      time_zone:,
                      json_encode: true,
                      **log_key_values )
        if event_note.blank?
          key_values = { event: event, timestamp: timestamp, time_zone: time_zone, class_name: class_name, id: id }
          event += '/'
        else
          key_values = { event: event,
                         event_note: event_note,
                         timestamp: timestamp,
                         time_zone: time_zone,
                         class_name: class_name,
                         id: id }
          event = "#{event}/#{event_note}"
        end
        key_values.merge! log_key_values
        key_values = logger_json_encode(value: key_values, json_encode: json_encode )
        "#{timestamp} #{event}/#{class_name}/#{id} #{key_values}"
      end

      def parse_log_line( line, line_number: nil, raw_key_values: false )
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

      def parse_log_line_key_values( key_values )
        ActiveSupport::JSON.decode key_values
      end

      def system_as_current_user
        "Deepblue"
      end

      def timestamp_now
        Time.now.to_formatted_s(:db )
      end

      def timestamp_zone
        DeepBlueDocs::Application.config.timezone_zone
      end

      def to_log_format_timestamp( timestamp )
        is_a_string = timestamp.is_a?( String )
        return timestamp if is_a_string && RE_TIMESTAMP_FORMAT =~ timestamp
        timestamp = Time.parse( timestamp ) if is_a_string
        timestamp = timestamp.to_formatted_s( :db ) if timestamp.is_a? Time
        timestamp.to_s
      end

      def update_attribute_key_values( curation_concern:,
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
          new_value = curation_concern_attribute( curation_concern: curation_concern, attribute: attribute )
          # puts "#{attribute}, #{old_value}, #{new_value}"
          new_update_attr_key_values[key] = { attribute: attribute,
                                              old_value: old_value,
                                              new_value: new_value } unless old_value == new_value
        end
        return new_update_attr_key_values
      end

      def curation_concern_attribute( curation_concern:, attribute: )
        case attribute
        when :visibility
          curation_concern.visibility
        else
          curation_concern[attribute]
        end
      end

    end

    extend ClassMethods

    def self.included( base )
      base.extend( ClassMethods )
    end

  end

end
