# frozen_string_literal: true

require_relative '../../../app/tasks/deepblue/abstract_task'
require_relative '../../../app/helpers/deepblue/report_helper'
require_relative '../../../app/services/deepblue/message_handler'
require_relative '../../../app/services/aptrust/aptrust'
require_relative '../../../app/services/aptrust/aptrust_config'
require_relative '../../../app/services/aptrust/aptrust_integration_service'
require_relative '../../../app/models/aptrust/status'

module Aptrust

  class AbstractTask < ::Deepblue::AbstractTask

    attr_accessor :aptrust_config
    attr_accessor :aptrust_config_file
    attr_accessor :date_begin
    attr_accessor :date_end
    attr_accessor :noids
    attr_accessor :test_date_begin
    attr_accessor :test_date_end
    attr_accessor :test_mode

    attr_accessor :export_dir
    attr_accessor :working_dir

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
      msg_handler.verbose = verbose if msg_handler.present?
      # @test_mode = option_value( key: 'test_mode', default_value: false ) # see below
      @noids = option_noids
      @date_begin = option_date_begin
      @date_end = option_date_end
      @export_dir = option_value( key: 'export_dir', default_value: nil )
      @working_dir = option_value( key: 'working_dir', default_value: nil )
      @export_dir = File.absolute_path @export_dir if @export_dir.present?
      @working_dir = File.absolute_path @working_dir if @working_dir.present?
    end

    def aptrust_config
      @aptrust_config ||= aptrust_config_init
    end

    def aptrust_config_init
      # msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "" ] if debug_verbose
      if @aptrust_config.blank?
        @aptrust_config = if @aptrust_config_file.present?
                            ::Aptrust::AptrustConfig.new( filename: @aptrust_config_filename )
                          else
                            ::Aptrust::AptrustConfig.new
                          end
      end
      @aptrust_config
    end

    def option_date_begin
      putsf "option_date_begin: @options['date_begin']=#{@options['date_begin']}" if verbose
      opt = task_options_value( key: 'date_begin', default_value: nil )
      # opt = DateTime.parse opt if opt.is_a? String
      opt = to_datetime( date: opt ) if opt.is_a? String
      return opt
    end

    def option_date_end
      putsf "option_date_end: @options['option_date_end']=#{@options['option_date_end']}" if verbose
      opt = task_options_value( key: 'date_end', default_value: nil )
      # opt = DateTime.parse opt if opt.is_a? String
      opt = to_datetime( date: opt ) if opt.is_a? String
      return opt
    end

    def option_noids
      opt = task_options_value( key: 'noids', default_value: '' )
      opt = opt.strip
      if /\s/ =~ opt
        opt = opt.split( /\s+/ )
      elsif opt.present?
        opt = Array( opt )
      else
        opt = []
      end
      putsf "noids=[#{opt.join(', ')}]" if verbose
      return opt
    end

    def option_value( key:, default_value: nil )
      rv = task_options_value( key: key, default_value: default_value )
      puts "#{key}=#{rv}" if verbose
      return rv
    end

    def putsf(obj='', *arg)
      puts obj, *arg
      STDOUT.flush
    end

    def readable_sz( size )
      DeepblueHelper.human_readable_size( size )
    end

    def test_dates_init
      putsf "Filter date_begin=#{date_begin}" if verbose
      putsf "Filter date_end=#{date_end}" if verbose
      @test_date_end = DateTime.now + 10.years
      @test_date_begin = @test_date_end - 50.years
      if !date_begin.nil? && !date_end.nil?
        putsf "Filtering by date begin: '#{options['date_begin']}' and date end: '#{options['date_end']}'" if verbose
        @test_date_begin = date_begin
        @test_date_end = date_end
      elsif !date_begin.nil? && date_end.nil?
        putsf "Filtering by date begin: '#{options['date_begin']}'" if verbose
        @test_date_begin = date_begin
      elsif date_begin.nil? && !date_end.nil?
        putsf "Filtering by modified date end: '#{options['date_end']}'" if verbose
        @test_date_end = date_end
      else
        putsf "Not filtering by date." if verbose
      end
    end

    def test_mode
      @test_mode ||= option_value( key: 'test_mode', default_value: false )
    end
    alias :test_mode? :test_mode

    def to_datetime( date:, format: nil, raise_errors: true, msg_postfix: '' )
      ::Deepblue::ReportHelper.to_datetime( date: date,
                                            format: format,
                                            msg_handler: @msg_handler,
                                            raise_errors: raise_errors,
                                            msg_postfix: msg_postfix )
    end

    def to_integer( num:, raise_errors: true )
      return nil if num.blank?
      num = num.to_s
      case num
      when /^([0-9_]+)\s*(kb|mb|gb|tb)$/i
        number = Regexp.last_match 1
        number = number.to_i
        unit = Regexp.last_match 2
        case unit
        when 'kb'
          return number * 1024
        when 'mb'
          return number * 1024 * 1024
        when 'gb'
          return number * 1024 * 1024 * 1024
        when 'tb'
          return number * 1024 * 1024 * 1024 * 1024
        else
          raise RuntimeError 'Should never get here.'
        end
      else
        begin
          return num.to.i
        rescue ArgumentError => e
          msg_handler.msg_error "Failed parse number string '#{num}'"
          raise e if raise_errors
        end
      end
    end


  end

end
