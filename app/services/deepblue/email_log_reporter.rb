# frozen_string_literal: true

module Deepblue

  require_relative './log_filter'
  require_relative './log_reporter'

  # rubocop:disable Metrics/ParameterLists
  class EmailLogReporter < LogReporter

    DEFAULT_REPORT_DAYS = true unless const_defined? :DEFAULT_REPORT_DAYS
    DEFAULT_REPORT_DAYS_NUM = 7 unless const_defined? :DEFAULT_REPORT_DAYS_NUM

    DEFAULT_REPORT_TAIL = false unless const_defined? :DEFAULT_REPORT_TAIL
    DEFAULT_REPORT_TAIL_NUM = 10 unless const_defined? :DEFAULT_REPORT_TAIL_NUM

    DEFAULT_REPORT_NUM = -1 unless const_defined? :DEFAULT_REPORT_NUM

    attr_reader :line_count, :num, :report_days, :report_days_num, :report_tail, :report_tail_num

    def initialize( filter: nil, input: nil, options: {} )
      super( input: initialize_input( input: input ), options: initialize_options( options: options ) )
      # super( filter: Deepblue::FixityCheckLogFilter.new, input: input, options: options )
      # filter_and( new_filters: filter ) if filter.present?
      puts "@options=#{@options}" if verbose
      @report_num = option( key: 'num', default_value: DEFAULT_REPORT_NUM ).to_i
      puts "@report_num=#{@report_num}" if verbose
      @report_days = option( key: 'days', default_value: DEFAULT_REPORT_DAYS )
      puts "@report_days=#{@report_days}" if verbose
      if @report_days && options_key?( 'days_num' ) && !option_key( 'num' )
        @report_days_num = option( key: 'days_num', default_value: DEFAULT_REPORT_DAYS_NUM ).to_i
      elsif @report_days
        @report_days_num = option( key: 'days_num', default_value: @report_num ).to_i
      end
      puts "@report_days_num=#{@report_days_num}" if verbose
      @report_tail = option( key: 'tail', default_value: DEFAULT_REPORT_TAIL )
      puts "@report_tail=#{@report_tail}" if verbose
      @report_days = false if options_key? 'tail'
      if @report_tail && options_key?( 'tail_num' ) && !option_key( 'num' )
        @report_tail_num = option( key: 'tail_num', default_value: DEFAULT_REPORT_TAIL_NUM ).to_i
      elsif @report_tail
        @report_tail_num = option( key: 'tail_num', default_value: @report_num ).to_i
      end
      puts "@report_tail_num=#{@report_tail_num}" if verbose
      if @begin_timestamp.present?
        add_date_range_filter
      elsif @report_tail && @report_tail_num > 0
        add_line_count_filter
      elsif @report_days && @report_days_num > 0
        add_days_date_range_filter
      end
      if options_key? 'events'
        @events = option( key: 'events', default_value: nil )
        add_events_filter( events: @events )
      end
    end

    def initialize_input( input: )
      return input if input.present?
      return "./log/email_production.log" if Rails.env.production?
      "./log/email_development.log"
    end

    def initialize_options( options: )
      puts "options=#{options}" if verbose
      # options = options.merge( { "verbose_filters": true } ) if verbose
      options
    end

    def add_days_date_range_filter
      begin_timestamp = DateTime.now.beginning_of_day
      puts "@report_days_num=#{@report_days_num}" if verbose
      if @report_days_num > 0
        begin_timestamp = begin_timestamp - @report_days_num.days
      end
      end_timestamp = DateTime.now
      puts "add_days_date_range_filter begin_timestamp=#{begin_timestamp} end_timestamp=#{end_timestamp}" if verbose
      new_filter = DateLogFilter.new( begin_timestamp: begin_timestamp, end_timestamp: end_timestamp )
      new_filter.verbose = verbose
      filter_and( new_filters: new_filter )
    end

    def add_events_filter( events: )
      puts "add_events_filter events=#{events} " if verbose
      new_filter = EventLogFilter.new( matching_events: events )
      new_filter.verbose = verbose
      filter_and( new_filters: new_filter )
    end

    def add_line_count_filter
      wc = `wc #{input}`
      return if wc.nil?
      wc.strip!
      return if wc.blank?
      if wc =~ /^\s*(\d+)\s.*$/
        lines = Regexp.last_match( 1 )
        lines = lines.to_i
        end_line_count = lines + 1
        if @report_tail_num > lines
          begin_line_count = 0
        else
          begin_line_count = lines - @report_tail_num
        end
        puts "add_line_count_filter begin_line_count=#{begin_line_count} end_line_count=#{end_line_count}" if verbose
        new_filter = LinesFilter.new( begin_line: begin_line_count, end_line: end_line_count )
        new_filter.verbose = verbose
        filter_and( new_filters: new_filter )
      end
    end

    # rubocop:disable Rails/Output
    def report
      run
      puts
      puts '#' * 40
      puts
      puts "Emails reported: #{@lines_reported}"
    end

    def report_line( line, timestamp, event, event_note, class_name, id, raw_key_values )
      key_values = parse_log_line_key_values( raw_key_values: raw_key_values )
      puts
      puts '>' * 40
      key_values.each_pair do |key,value|
        if key == 'body'
          if value.is_a? Array
            puts "#{key}:\n#{value.join("    \n")}"
          elsif '[' == value.first
            puts "#{key}:\n#{JSON.parse( body ).first}"
          else
            puts "#{key}:\n#{value}"
          end
        else
          puts "#{key}: #{value}"
        end
      end
      puts '<' * 40
    end
    # rubocop:enable Rails/Output

    protected

      def initialize_report_values
        super()
        @line_count = 0
      end

      def line_read( reader, line, timestamp, event, event_note, class_name, id, raw_key_values )
        super( reader, line, timestamp, event, event_note, class_name, id, raw_key_values )
        report_line( line, timestamp, event, event_note, class_name, id, raw_key_values )
      end

      def parse_log_line_key_values( raw_key_values: )
        ProvenanceHelper.parse_log_line_key_values raw_key_values
      end

  end
  # rubocop:enable Metrics/ParameterLists

end
