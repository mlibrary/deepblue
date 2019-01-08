# frozen_string_literal: true

module Deepblue

  # see: http://ruby-doc.org/stdlib-2.0.0/libdoc/benchmark/rdoc/Benchmark.html
  require 'benchmark'
  include Benchmark

  module TaskHelper

    def self.all_works
      if dbd_version_1?
        GenericWork.all
      else
        DataSet.all
      end
    end

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

    def self.dbd_version_1?
      DeepBlueDocs::Application.config.dbd_version == 'DBDv1'
    end

    def self.dbd_version_2?
      DeepBlueDocs::Application.config.dbd_version == 'DBDv2'
    end

    def self.ensure_dirs_exist( *dirs )
      dirs.each { |dir| Dir.mkdir( dir ) unless Dir.exist?( dir ) }
    end

    def self.hydra_model_work?( hydra_model: )
      if dbd_version_1?
        'GenericWork' == hyrda_model
      else
        'DataSet' == hydra_model
      end
    end

    def self.human_readable_size( value )
      value = value.to_i
      return ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert( value, precision: 3 )
    end

    def self.logger_new( logger_level: Logger::INFO )
      TaskLogger.new( STDOUT ).tap do |logger|
        logger.level = logger_level
        Rails.logger = logger
      end
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

    def self.target_file_name( file_set:, files_extracted: )
      target_file_name = file_set.label
      if files_extracted.key? target_file_name
        dup_count = 1
        base_ext = File.extname target_file_name
        base_target_file_name = File.basename target_file_name, base_ext
        target_file_name = base_target_file_name + "_" + dup_count.to_s.rjust( 3, '0' ) + base_ext
        while files_extracted.key? target_file_name
          dup_count += 1
          target_file_name = base_target_file_name + "_" + dup_count.to_s.rjust( 3, '0' ) + base_ext
        end
      end
      files_extracted.store( target_file_name, true )
      return target_file_name
    end

    def self.task_options_error?( options )
      task_options_error( options, key: 'error', default_value: false )
    end

    def self.task_options_parse( options_str )
      return options_str if options_str.is_a? Hash
      return {} if options_str.blank?
      ActiveSupport::JSON.decode options_str
    rescue ActiveSupport::JSON.parse_error => e
      return { 'error': e, 'options_str': options_str }
    end

    def self.task_options_value( options, key:, default_value: nil, verbose: false )
      return default_value if options.blank?
      return default_value unless options.key? key
      # if [true, false].include? default_value
      #   return options[key].to_bool
      # end
      puts "set key #{key} to #{options[key]}" if verbose
      return options[key]
    end

    def self.work?( obj )
      if dbd_version_1?
        obj.is_a? GenericWork
      else
        obj.is_a? DataSet
      end
    end

    def self.work_discipline( work: )
      if dbd_version_1?
        work.subject
      else
        work.subject_discipline
      end
    end

    def self.work_find( id: )
      if dbd_version_1?
        GenericWork.find id
      else
        DataSet.find id
      end
    end

  end

end
