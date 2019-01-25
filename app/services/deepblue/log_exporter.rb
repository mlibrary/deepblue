# frozen_string_literal: true

module Deepblue

  require 'json'

  # rubocop:disable Metrics/ParameterLists
  class LogExporter < LogReader

    DEFAULT_PP_EXPORT = false

    attr_accessor :output, :output_mode
    attr_reader :lines_exported
    attr_reader :output_close, :output_pathname
    attr_accessor :pp_export

    def initialize( filter: nil, input:, output:, options: {} )
      super( filter: filter, input: input, options: options )
      @output = output
      @pp_export = option( key: 'pp_export', default_value: DEFAULT_PP_EXPORT )
      puts "pp_export=#{pp_export}" if verbose
    end

    def export_line( line, timestamp, event, event_note, class_name, id, raw_key_values )
      if pp_export
        pretty_print_line line, timestamp, event, event_note, class_name, id, raw_key_values
      else
        @output.puts line
      end
    end

    def pretty_print_line( line, timestamp, event, event_note, class_name, id, raw_key_values )
      @output.puts "#{timestamp} #{event}/#{event_note}/#{class_name}/#{id}"
      @output.puts JSON.pretty_generate( JSON.parse( raw_key_values ) )
    end

    def output_mode
      @output_mode ||= option( key: 'output_mode', default_value: 'w' )
    end

    def run
      @lines_exported = 0
      log_open_output
      readlines do |line, timestamp, event, event_note, class_name, id, raw_key_values|
        export_line line, timestamp, event, event_note, class_name, id, raw_key_values
        @lines_exported += 1
      end
    ensure
      log_close_output
    end

    # rubocop:disable Rails/Output
    def quick_report
      super
      puts "output_pathname: #{@output_pathname}"
      puts "lines_exported: #{@lines_exported}"
    end
    # rubocop:enable Rails/Output

    protected

      def log_close_output
        return unless @output_close
        @output.flush unless @output.nil? # rubocop:disable Style/SafeNavigation
        @output.close unless @output.nil? # rubocop:disable Style/SafeNavigation
      end

      def log_open_output
        # puts "@output=#{@output}"
        @output_pathname = Pathname.new @output if @output.is_a? String
        # puts "@output_pathname=#{@output_pathname}"
        @output_pathname = @output if @output.is_a? Pathname
        # puts "@output_pathname=#{@output_pathname}"
        # return if @output_pathname.blank? # TODO: why doesn't this work
        # puts "output_mode=#{output_mode}"
        @output = open( @output_pathname, output_mode )
        @output_close = true
      end

  end
  # rubocop:enable Metrics/ParameterLists

end
