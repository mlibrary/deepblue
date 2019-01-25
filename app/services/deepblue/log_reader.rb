# frozen_string_literal: true

module Deepblue

  require_relative './log_filter'

  class LogReader

    DEFAULT_BEGIN_TIMESTAMP = ''
    DEFAULT_END_TIMESTAMP = ''
    DEFAULT_TIMESTAMP_FORMAT = ''
    DEFAULT_VERBOSE = false

    attr_accessor :verbose

    attr_reader :current_line
    attr_reader :date_range_filter
    attr_reader :filter # , :filter_predicate
    attr_reader :input, :input_pathname, :input_mode, :input_close
    attr_reader :lines_parsed, :lines_read
    attr_reader :options
    attr_reader :parsed,
                :parsed_timestamp,
                :parsed_event,
                :parsed_event_note,
                :parsed_class_name,
                :parsed_id,
                :parsed_raw_key_values

    def initialize( filter: nil,
                    # filter_predicate: ->( _timestamp, _event, _event_note, _class_name, _id, _key_values ) { true },
                    input:,
                    options: {} )

      @filter = initialize_filter filter
      # @filter_predicate = filter_predicate
      @input = input
      @options = options
      @verbose = option( key: 'verbose', default_value: DEFAULT_VERBOSE )
      add_date_range_filter
    end

    def initialize_filter( filter )
      return AllLogFilter.new if filter.blank?
      return AndLogFilter( filters: filter ) if filter.is_a? Array
      filter
    end

    def add_date_range_filter
      begin_timestamp = option( key: 'begin' )
      begin_timestamp = option( key: 'begin_timestamp', default_value: DEFAULT_BEGIN_TIMESTAMP ) unless begin_timestamp.present?
      end_timestamp = option( key: 'end' )
      end_timestamp = option( key: 'end_timestamp', default_value: DEFAULT_END_TIMESTAMP ) unless end_timestamp.present?
      timestamp_format = option( key: 'format' )
      timestamp_format = option( key: 'timestamp_format', default_value: DEFAULT_TIMESTAMP_FORMAT ) unless timestamp_format.present?
      puts "add_date_range_filter begin_timestamp=#{begin_timestamp} end_timestamp=#{end_timestamp}" if verbose # rubocop:disable Rails/Output
      return if begin_timestamp.blank? && end_timestamp.blank?
      @date_range_filter = DateLogFilter.new( begin_timestamp: begin_timestamp,
                                              end_timestamp: end_timestamp,
                                              timestamp_format: timestamp_format )
      filter_and( new_filters: date_range_filter )
    end

    def filter_and( new_filters:, append: true )
      return if new_filters.blank?
      current_filter = @filter
      @filter = if current_filter.all_log_filter?
                  if new_filters.is_a? Array
                    AndLogFilter.new( filters: new_filters )
                  else
                    new_filters
                  end
                elsif append
                  current_filter.and( new_filters: new_filters )
                else
                  new_filters = Array( new_filters )
                  new_filters.concat current_filter
                  AndLogFilter.new( filters: new_filters )
                end
      puts "filter_and @filter=#{@filter}" if verbose # rubocop:disable Rails/Output
    end

    def filter_or( new_filters:, append: true )
      return if new_filters.blank?
      current_filter = @filter
      @filter = if append && current_filter.all_log_filter?
                  current_filter # new_filters are unreachable, so ignore
                elsif append
                  current_filter.or( new_filters: new_filters )
                else
                  new_filters = Array( new_filters )
                  new_filters.concat current_filter
                  OrLogFilter.new( filters: new_filters )
                end
    end

    def input_mode
      @input_mode ||= option( key: 'input_mode', default_value: 'r' )
    end

    def parse_line
      # line is of the form: "timestamp event/event_note/class_name/id key_values"
      @parsed_timestamp = nil
      @parsed_event = nil
      @parsed_event_note = nil
      @parsed_class_name = nil
      @parsed_id = nil
      @parsed_raw_key_values = nil
      @parsed = false
      return if @current_line.blank?
      @parsed_timestamp,
          @parsed_event,
          @parsed_event_note,
          @parsed_class_name,
          @parsed_id,
          @parsed_raw_key_values = ProvenanceHelper.parse_log_line( @current_line,
                                                                    line_number: @lines_read,
                                                                    raw_key_values: true )
      @lines_parsed += 1
      @parsed = true
    rescue LogParseError => e
      puts e.message # rubocop:disable Rails/Output
    end

    # rubocop:disable Rails/Output
    def quick_report
      puts
      puts "Quick report"
      puts "input_pathname: #{input_pathname}"
      puts "lines_read: #{lines_read}"
      puts "lines_parsed: #{lines_parsed}"
    end
    # rubocop:enable Rails/Output

    def readlines( &for_filtered_line_block )
      @lines_parsed = 0
      @lines_read = 0
      log_open_input
      # for each line of input
      @current_line = nil
      line_filter = filter
      until @input.eof?
        @current_line = @input.readline
        @current_line.chop!
        @lines_read += 1
        parse_line
        next unless @parsed
        # next @filter_predicate.call( @parsed_timestamp,
        next unless line_filter.filter_in( @parsed_timestamp,
                                           @parsed_event,
                                           @parsed_event_note,
                                           @parsed_class_name,
                                           @parsed_id,
                                           @parsed_raw_key_values )
        next unless for_filtered_line_block
        yield( @current_line,
               @parsed_timestamp,
               @parsed_event,
               @parsed_event_note,
               @parsed_class_name,
               @parsed_id,
               @parsed_raw_key_values )
      end
    ensure
      log_close_input
    end

    protected

      def log_close_input
        return unless @input_close
        @input.close unless @input.nil? # rubocop:disable Style/SafeNavigation
      end

      def log_open_input
        @input_pathname = Pathname.new @input if @input.is_a? String
        @input_pathname = @input if @input.is_a? Pathname
        return unless @input_pathname.exist?
        @input = open( @input_pathname, 'r' )
        @input_close = true
      end

      def option( key:, default_value: nil )
        return default_value unless options_key? key
        return @options[key] if @options.key? key
        return @options[key.to_sym] if key.is_a? String
        return @options[key.to_s] if key.is_a? Symbol
        return default_value
      end

      def options_key?( key )
        return true if @options.key? key
        return @options.key? key.to_sym if key.is_a? String
        return @options.key? key.to_s if key.is_a? Symbol
        return false
      end

  end

end
