# frozen_string_literal: true

module Deepblue

  class AbstractLogTask < AbstractTask

    DEFAULT_BEGIN = '' unless const_defined? :DEFAULT_BEGIN
    DEFAULT_END = '' unless const_defined? :DEFAULT_END
    DEFAULT_FORMAT = '' unless const_defined? :DEFAULT_FORMAT
    DEFAULT_INPUT = './log/provenance_production.log' unless const_defined? :DEFAULT_INPUT
    DEFAULT_OUTPUT = '' unless const_defined? :DEFAULT_OUTPUT

    attr_accessor :input, :options_to_pass, :output

    attr_accessor :begin_timestamp, :end_timestamp, :format_timestamp

    def initialize( options: {}, pass_all_options: false )
      super( options: options )

      @options_to_pass = {}
      @options_to_pass['verbose'] = verbose
      @options_to_pass['pp_export'] = task_options_value( key: 'pp_export' )

      @input = initialize_input
      @output = initialize_output

      @begin_timestamp = task_options_value( key: 'begin', default_value: DEFAULT_BEGIN )
      @options_to_pass['begin_timestamp'] = @begin_timestamp if @begin_timestamp.present?
      @end_timestamp = task_options_value( key: 'end', default_value: DEFAULT_END )
      @options_to_pass['end_timestamp'] = @end_timestamp if @end_timestamp.present?
      @timestamp_format = task_options_value( key: 'format', default_value: DEFAULT_FORMAT )
      @options_to_pass['timestamp_format'] = @format_timestamp if @timestamp_format.present?

      @options_to_pass.merge!( @options ) if pass_all_options
    end

    def initialize_input
      task_options_value( key: 'input', default_value: DEFAULT_INPUT )
    end

    def initialize_output
      rv = task_options_value( key: 'output', default_value: DEFAULT_OUTPUT )
      return rv if rv.present?
      rv = "#{@input}.out" if @input.present?
      return rv
    end

    def run
      puts "input reading from #{@input}" if verbose
      @exporter.run
      puts "output written to #{@output}" if verbose
    end

  end

end
