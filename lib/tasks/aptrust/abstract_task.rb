# frozen_string_literal: true

require_relative '../../../app/tasks/deepblue/abstract_task'
require_relative '../../../app/helpers/deepblue_helper'
require_relative '../../../app/helpers/deepblue/email_helper'
require_relative '../../../app/helpers/deepblue/report_helper'
require_relative '../../../app/services/deepblue/message_handler'
require_relative '../../../app/services/aptrust/aptrust'
require_relative '../../../app/services/aptrust/aptrust_config'
require_relative '../../../app/services/aptrust/aptrust_integration_service'
require_relative '../../../app/services/aptrust/work_cache'
require_relative '../../../app/models/aptrust/status'

module Aptrust

  class AbstractTask < ::Deepblue::AbstractTask

    mattr_accessor :aptrust_abstract_aptrust_debug_verbose, default: false

    attr_accessor :aptrust_config
    attr_accessor :aptrust_config_file
    attr_accessor :date_begin
    attr_accessor :date_end
    attr_accessor :email_results
    attr_accessor :email_subject
    attr_accessor :email_targets
    attr_accessor :export_dir
    attr_accessor :noids
    attr_accessor :test_date_begin
    attr_accessor :test_date_end
    attr_accessor :test_mode
    attr_accessor :working_dir

    attr_accessor :task_options # TODO: start using
    attr_accessor :track_status

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
      option_email_targets_present = task_options_value( key: 'email_targets', default_value: nil ).present?
      @msg_handler.verbose = verbose? if @msg_handler.present?
      @msg_handler.msg_queue = [] if option_email_targets_present && @msg_handler.present? && @msg_handler.msg_queue.nil?
      # @test_mode = option_value( key: 'test_mode', default_value: false ) # see below
      @noids         = option_noids
      @date_begin    = option_date_begin
      @date_end      = option_date_end
      @email_results = task_options_value( key: 'email_results', default_value: true )
      @email_subject = task_options_value( key: 'email_subject', default_value: '' )
      @email_targets = option_email_targets
      @export_dir    = option_path( key: 'export_dir' )
      @track_status  = option_value( key: 'track_status', default_value: true )
      @working_dir   = option_path( key: 'working_dir' )
      @test_mode     = option_value( key: 'test_mode', default_value: false )
      @task_options  = options.dup # TODO: start using
      msg_handler.msg_debug( [ msg_handler.here, msg_handler.called_from,
                               "@track_status=#{@track_status}" ] ) if msg_handler.present?
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

    def human_readable_size( value )
      value = value.to_i
      return ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert( value, precision: 3 )
    end

    def msg_handler_queue_to_html
      # ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
      #                                       "msg_handler=#{msg_handler.pretty_inspect}" ] if true
      html = "<pre>\n#{msg_handler.join("\n")}\n</pre>"
      return html
    end

    def option_date_begin
      msg_handler.msg_debug "option_date_begin: @options['date_begin']=#{@options['date_begin']}" if debug_verbose
      opt = task_options_value( key: 'date_begin', default_value: nil )
      # opt = DateTime.parse opt if opt.is_a? String
      opt = to_datetime( date: opt ) if opt.is_a? String
      return opt
    end

    def option_date_end
      msg_handler.msg_debug "option_date_end: @options['option_date_end']=#{@options['option_date_end']}" if debug_verbose
      opt = task_options_value( key: 'date_end', default_value: nil )
      # opt = DateTime.parse opt if opt.is_a? String
      opt = to_datetime( date: opt ) if opt.is_a? String
      return opt
    end

    def option_email_targets( default_value: '' )
      key = 'email_targets'.freeze
      opt = task_options_value( key: key, default_value: default_value )
      opt = opt.strip
      if /\s/ =~ opt
        opt = opt.split( /\s+/ )
      elsif opt.present?
        opt = Array( opt )
      else
        opt = []
      end
      msg_handler.msg_debug "#{key}=[#{opt.join(', ')}]" if debug_verbose
      return opt
    end

    def option_integer( key:, default_value: nil )
      opt = task_options_value( key: key, default_value: default_value )
      return opt if opt.nil?
      opt = opt.strip if opt.is_a? String
      opt = to_integer( num: opt ) if opt.is_a? String
      msg_handler.msg_debug "#{key}='#{opt}'"
      return opt
    end

    def option_noids
      key = 'noids'.freeze
      opt = task_options_value( key: key, default_value: '' )
      opt = opt.strip
      if /\s/ =~ opt
        opt = opt.split( /\s+/ )
      elsif opt.present?
        opt = Array( opt )
      else
        opt = []
      end
      msg_handler.msg_debug "#{key}=[#{opt.join(', ')}]"
      return opt
    end

    def option_path( key:, default_value: nil )
      opt = option_value( key: key, default_value: default_value )
      opt = File.absolute_path opt if opt.present?
      return opt
    end

    def option_value( key:, default_value: nil )
      rv = task_options_value( key: key, default_value: default_value )
      msg_handler.msg_debug "#{key}=#{rv}" if debug_verbose
      return rv
    end

    def putsf(obj='', *arg)
      puts obj, *arg
      STDOUT.flush
    end

    def readable_sz( size )
      DeepblueHelper.human_readable_size( size )
    end

    def datetime_local_time( datetime, format: nil )
      return datetime unless datetime.present?
      rv = datetime
      rv = rv.to_datetime if rv.is_a? Time
      rv = DateTime.parse rv if rv.is_a? String
      rv = rv.new_offset( Rails.configuration.timezone_offset ) if Rails.configuration.datetime_stamp_display_local_time_zone
      rv = rv.strftime( format ) if format.present?
      return rv
    end

    def run_email_subject( subject: )
      # ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
      #                                       "subject=#{subject}",
      #                                       "email_subject=#{email_subject}" ] if true
      return subject unless email_subject.present?
      new_subject = email_subject
      # replace subject macro values
      now = datetime_local_time( DateTime.now )
      new_subject = new_subject.gsub( /\%subject\%/,       subject ) if subject.present?
      new_subject = new_subject.gsub( /\%hostname\%/,      ::Deepblue::ReportHelper.hostname_short )
      new_subject = new_subject.gsub( /\%hostname_full\%/, Rails.configuration.hostname )
      new_subject = new_subject.gsub( /\%now\%/,           now.to_s )
      new_subject = new_subject.gsub( /\%date\%/,          now.strftime('%Y-%m-%d') )
      new_subject = new_subject.gsub( /\%time\%/,          now.strftime('%H:%M:%S') )
      new_subject = new_subject.gsub( /\%timestamp\%/,     ::DeepblueHelper.display_timestamp( DateTime.now ) )
      return new_subject
    end

    def run_email_targets( subject:, body: nil, event: '', event_note: '', debug_verbose: false )
      return unless email_results
      subject = run_email_subject( subject: subject )
      body ||= msg_handler_queue_to_html
      ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
                                            "subject=#{subject}",
                                            "body=#{body}" ] if aptrust_abstract_aptrust_debug_verbose
      email_targets.each do |email|
        email_sent = ::Deepblue::EmailHelper.send_email( to: email,
                                                         subject: subject,
                                                         body: body,
                                                         content_type: ::Deepblue::EmailHelper::TEXT_HTML )
        ::Deepblue::EmailHelper.log( class_name: self.class.name,
                                     current_user: nil,
                                     event: event,
                                     event_note: event_note,
                                     id: "N/A",
                                     to: email,
                                     subject: subject,
                                     body: body,
                                     content_type: ::Deepblue::EmailHelper::TEXT_HTML,
                                     email_sent: email_sent )

      end
    end

    def status_created_at( noid: )
      rv = ::Aptrust::Status.for_id( noid: noid )
      return nil if rv.blank?
      rv = rv.first
      rv = rv.created_at
      return rv
    end

    def test_dates_init
      msg_handler.msg_debug "Filter date_begin=#{date_begin}" if debug_verbose
      msg_handler.msg_debug "Filter date_end=#{date_end}" if debug_verbose
      @test_date_end = DateTime.now + 10.years
      @test_date_begin = @test_date_end - 50.years
      if !date_begin.nil? && !date_end.nil?
        msg_handler.msg_verbose "Filtering by date begin: '#{options['date_begin']}' and date end: '#{options['date_end']}'"
        @test_date_begin = date_begin
        @test_date_end = date_end
      elsif !date_begin.nil? && date_end.nil?
        msg_handler.msg_verbose "Filtering by date begin: '#{options['date_begin']}'"
        @test_date_begin = date_begin
      elsif date_begin.nil? && !date_end.nil?
        msg_handler.msg_verbose "Filtering by modified date end: '#{options['date_end']}'"
        @test_date_end = date_end
      else
        msg_handler.msg_verbose "Not filtering by date."
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

    def w_all( solr: true )
      if solr
        rv = ActiveFedora::SolrService.query("+(has_model_ssim:DataSet)", rows: 100_000)
      else
        rv = DataSet.all
      end
      return rv
    end

  end

end
