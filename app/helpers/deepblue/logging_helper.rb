# frozen_string_literal: true

module Deepblue

  module LoggingHelper

    def self.bold_error( msg = nil, label: nil, key_value_lines: true, add_stack_trace: false, lines: 1, &block )
      lines = 1 unless lines.positive?
      lines.times { Rails.logger.error "<<<<<<<<<< BEGIN ERROR >>>>>>>>>>" }
      Rails.logger.error label if label.present?
      if msg.respond_to?( :each )
        msg.each do |m|
          if key_value_lines && m.respond_to?( :each_pair )
            m.each_pair { |k, v| Rails.logger.error "#{k}: #{v}" }
          else
            Rails.logger.error m
          end
        end
        caller_locations(2).each { |m| Rails.logger.debug m } if add_stack_trace
        Rails.logger.debug nil, &block if block_given?
      elsif add_stack_trace
        Rails.logger.debug msg
        caller_locations(2).each { |m| Rails.logger.debug m } if add_stack_trace
        Rails.logger.debug nil, &block if block_given?
      else
        Rails.logger.error msg, &block
      end
      lines.times { Rails.logger.error "<<<<<<<<<<< END ERROR >>>>>>>>>>>" }
    end

    def self.bold_debug( msg = nil, bold_puts: false, label: nil, key_value_lines: true, add_stack_trace: false, lines: 1, &block )
      bold_puts( msg,
                  label: label,
                  key_value_lines: key_value_lines,
                  add_stack_trace: add_stack_trace,
                  lines: lines,
                  &block ) if bold_puts
      lines = 1 unless lines.positive?
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
        caller_locations(2).each { |m| Rails.logger.debug m } if add_stack_trace
        Rails.logger.debug nil, &block if block_given?
      elsif add_stack_trace
        Rails.logger.debug msg
        caller_locations(2).each { |m| Rails.logger.debug m } if add_stack_trace
        Rails.logger.debug nil, &block if block_given?
      else
        Rails.logger.debug msg, &block
      end
      lines.times { Rails.logger.debug ">>>>>>>>>>" }
    end

    def self.bold_puts( msg = nil,
        bold_debug: false,
        label: nil,
        key_value_lines: true,
        add_stack_trace: false,
        lines: 1,
        &block )

      bold_debug( msg,
                  label: label,
                  key_value_lines: key_value_lines,
                  add_stack_trace: add_stack_trace,
                  lines: lines,
                  &block ) if bold_debug
      lines = 1 unless lines.positive?
      lines.times { puts ">>>>>>>>>>" }
      puts label if label.present?
      if msg.respond_to?( :each )
        msg.each do |m|
          if key_value_lines && m.respond_to?( :each_pair )
            m.each_pair { |k, v| puts "#{k}: #{v}" }
          else
            puts m
          end
        end
        caller_locations(2).each { |m| puts m } if add_stack_trace
        # Rails.logger.debug nil, &block if block_given?
      elsif add_stack_trace
        puts msg
        caller_locations(2).each { |m| puts m } if add_stack_trace
        # Rails.logger.debug nil, &block if block_given?
      else
        # Rails.logger.debug msg, &block
      end
      lines.times { puts ">>>>>>>>>>" }
    end

    def self.called_from
      "called from: #{caller_locations(1, 2)[1]}"
    end

    def self.caller
      "#{caller_locations(1, 2)[1]}"
    end

    def self.debug( msg = nil, label: nil, key_value_lines: true, lines: 0, &block )
      lines = 0 if lines.negative?
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

    def self.here
      "#{caller_locations(1, 1)[0]}"
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
                  time_zone: LoggingHelper.timestamp_zone,
                  echo_to_rails_logger: true,
                  logger: Rails.logger,
                  **key_values )

      msg = msg_to_log( class_name: class_name,
                        event: event,
                        event_note: event_note,
                        id: id,
                        timestamp: timestamp,
                        time_zone: time_zone,
                        **key_values )
      logger.info msg
      Rails.logger.info msg if echo_to_rails_logger
    end

    def self.msg_to_log( class_name:,
                         event:,
                         event_note:,
                         id:, timestamp:,
                         time_zone:,
                         json_encode: true,
                         **added_key_values )
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
      key_values.merge! added_key_values
      key_values = ActiveSupport::JSON.encode key_values if json_encode
      "#{timestamp} #{event}/#{class_name}/#{id} #{key_values}"
    end

    def self.obj_attribute_names( label, obj )
      return "#{label}.attribute_names=N/A" unless obj.respond_to? :attribute_names
      "#{label}.attribute_names=#{obj.attribute_names}"
    end

    def self.obj_class( label, obj )
      "#{label}.class=#{obj.class.name}"
    end

    def self.obj_instance_variables( label, obj )
      "#{label}.instance_variables=#{obj.instance_variables}"
    end

    def self.obj_methods( label, obj )
      "#{label}.methods=#{obj.methods.sort}"
    end

    def self.obj_to_json( label, obj )
      return "#{label}.to_json=N/A" unless obj.respond_to? :to_json
      "#{label}.to_json=#{obj.to_json}"
    end

    def self.strip_html_for_debug_dump( html )
      rv = []
      in_script = false
      html.split("\n").each do |line|
        case line
        when /^\s*$/
          # strip
          # rv << "strip whitespace: " + line
        when /^\s*\<link .+\>\s*$/
          # strip
          # rv << "strip link: " + line
        when /^\s*\<meta .+\>\s*$/
          # strip
          # rv << "strip meta: " + line
        when /^\s*\<script.+\<\/script\>\s*$/
          # strip
          # rv << "strip single script: " + line
        when /^\s*\<script.*$/
          # strip
          in_script = true
          # rv << "strip start script: " + line
        when /^.*\<\/script\>\s*$/
          # strip
          in_script = false
          # rv << "strip end script: " + line
        else
          # strip trailing comment:
          if line =~ /^(.*)\<\!\-\-.*\-\->\s*$/
            line = Regexp.last_match[1]
          end
          rv << line unless in_script
          # rv << "strip in_script: " + line if in_script
        end
      end
      rv.join( "\n" )
    end

    def self.system_as_current_user
      "Deepblue"
    end

    def self.timestamp_now
      Time.now.to_formatted_s(:db )
    end

    def self.timestamp_zone
      DeepBlueDocs::Application.config.timezone_zone
    end

    def self.to_log_format_timestamp( timestamp )
      timestamp = Time.parse( timestamp ) if timestamp.is_a? String
      timestamp = timestamp.to_formatted_s( :db ) if timestamp.is_a? Time
      timestamp.to_s
    end

  end

end
