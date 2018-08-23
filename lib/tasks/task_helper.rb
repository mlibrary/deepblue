# frozen_string_literal: true

module Deepblue

  # see: http://ruby-doc.org/stdlib-2.0.0/libdoc/benchmark/rdoc/Benchmark.html
  require 'benchmark'
  include Benchmark

  module TaskHelper

    def self.benchmark_report( label:, first_id:, measurements:, total: nil )
      label += ' ' * (first_id.size - label.size)
      puts "#{label} #{Benchmark::CAPTION}"
      format = Benchmark::FORMAT.chop
      measurements.each do |measurement|
        label = measurement.label
        puts measurement.format( "#{label} #{format} is #{seconds_to_readable(measurement.real)}\n" )
      end
      return if total.blank?
      label = 'total'
      label += ' ' * (first_id.size - label.size)
      puts total.format( "#{label} #{format} is #{seconds_to_readable(total.real)}\n" )
    end

    def self.seconds_to_readable( seconds )
      h, min, s, _fr = split_seconds( seconds )
      return "#{h} hours, #{min} minutes, and #{s} seconds"
    end

    def self.split_seconds( fr )
      # ss,  fr = fr.divmod(86_400) # 4p
      ss = ( fr + 0.5 ).to_int
      h,   ss = ss.divmod(3600 )
      min, s  = ss.divmod(60 )
      return h, min, s, fr
    end

    def self.task_options_error?( options )
      task_options_error( options, key: 'error', default_value: false )
    end

    def self.task_options_parse( options_str )
      return {} if options_str.blank?
      ActiveSupport::JSON.decode options_str
    rescue ActiveSupport::JSON.parse_error => e
      return { 'error': e, 'options_str': options_str }
    end

    def self.task_options_value( options, key:, default_value: nil )
      return default_value if options.blank?
      return default_value unless options.key? key
      return options[key]
    end

  end

end
