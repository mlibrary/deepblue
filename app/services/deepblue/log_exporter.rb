# frozen_string_literal: true

module Deepblue

  # rubocop:disable Metrics/ParameterLists
  class LogExporter < LogReader

    attr_reader :lines_exported
    attr_reader :output, :output_close, :output_mode, :output_pathname

    def initialize( filter: nil, input:, output:, options: {} )
      super( filter: filter, input: input, options: options )
      @output = output
    end

    def output_mode
      @output_mode ||= option( key: 'output_mode', default_value: 'w' )
    end

    def run
      @lines_exported = 0
      log_open_output
      readlines do |line, _timestamp, _event, _event_note, _class_name, _id, _raw_key_values|
        @output.puts line
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
