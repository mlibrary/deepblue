# frozen_string_literal: true

require_relative '../../../app/tasks/deepblue/abstract_task'
require_relative '../../../app/helpers/deepblue/email_helper'
require_relative '../../../app/helpers/deepblue/report_helper'
require_relative '../../../app/services/deepblue/message_handler'
require_relative '../../../app/services/aptrust/aptrust'
require_relative '../../../app/services/aptrust/aptrust_config'
require_relative '../../../app/services/aptrust/aptrust_integration_service'
require_relative '../../../app/models/aptrust/status'

module Aptrust

  class WorkCache

    attr_accessor :noid
    attr_accessor :work
    attr_accessor :solr

    def initialize( noid: nil, work: nil, solr: true )
      @noid = noid
      @work = work
      @solr = solr
      @date_modified = nil
    end

    def reset
      @noid = nil
      @work = nil
      @date_modified = nil
      return self
    end

    def work
      @work ||= work_init
    end

    def work_init
      if @solr
        rv = ActiveFedora::SolrService.query("id:#{noid}", rows: 1)
        rv = rv.first
      else
        rv = PersistHelper.find @noid
      end
      return rv
    end

    def date_modified
      if @solr
        rv = date_modified_solr
      else
        rv = work.date_modified
      end
      return rv
    end

    def date_modified_solr
      @date_modified ||= date_modified_solr_init
    end

    def date_modified_solr_init
      rv = work['date_modified_dtsi']
      rv = DateTime.parse rv
      return rv
    end

    def file_set_ids
      if @solr
        rv = work['file_set_ids_ssim']
      else
        rv = work.file_set_ids
      end
      return rv
    end

    def id
      if @solr
        rv = work['id']
      else
        rv = work.id
      end
      return rv
    end

    def published?
      if @solr
        rv = published_solr?
      else
        rv = work.published?
      end
      return rv
    end

    def published_solr?
      doc = work
      return false unless doc['visibility_ssi'] == 'open'
      return false unless doc['workflow_state_name_ssim'] = ["deposited"]
      return false if doc['suppressed_bsi']
      return true
    end

    def total_file_size
      if @solr
        rv = work['total_file_size_lts']
      else
        rv = work.total_file_size
      end
      return rv
    end

  end

  class AbstractTask < ::Deepblue::AbstractTask

    attr_accessor :aptrust_config
    attr_accessor :aptrust_config_file
    attr_accessor :date_begin
    attr_accessor :date_end
    attr_accessor :email_targets
    attr_accessor :export_dir
    attr_accessor :noids
    attr_accessor :test_date_begin
    attr_accessor :test_date_end
    attr_accessor :test_mode
    attr_accessor :working_dir

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
      msg_handler.verbose = verbose if msg_handler.present?
      msg_handler.msg_queue = [] if msg_handler.present? && msg_handler.msg_queue.nil?
      # @test_mode = option_value( key: 'test_mode', default_value: false ) # see below
      @noids = option_noids
      @date_begin = option_date_begin
      @date_end = option_date_end
      @email_targets = option_email_targets
      @export_dir = option_path( key: 'export_dir' )
      @working_dir = option_path( key: 'working_dir' )
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

    def msg_handler_queue_to_html
      msg = "<pre>\n#{msg_handler.join("\n")}\n</pre>"
      return msg
    end

    def option_date_begin
      msg_handler.msg_verbose "option_date_begin: @options['date_begin']=#{@options['date_begin']}" if verbose
      opt = task_options_value( key: 'date_begin', default_value: nil )
      # opt = DateTime.parse opt if opt.is_a? String
      opt = to_datetime( date: opt ) if opt.is_a? String
      return opt
    end

    def option_date_end
      msg_handler.msg_verbose "option_date_end: @options['option_date_end']=#{@options['option_date_end']}" if verbose
      opt = task_options_value( key: 'date_end', default_value: nil )
      # opt = DateTime.parse opt if opt.is_a? String
      opt = to_datetime( date: opt ) if opt.is_a? String
      return opt
    end

    def option_email_targets
      key = 'email_targets'.freeze
      opt = task_options_value( key: key, default_value: '' )
      opt = opt.strip
      if /\s/ =~ opt
        opt = opt.split( /\s+/ )
      elsif opt.present?
        opt = Array( opt )
      else
        opt = []
      end
      msg_handler.msg_verbose "#{key}=[#{opt.join(', ')}]" if verbose
      return opt
    end

    def option_integer( key:, default_value: nil )
      opt = task_options_value( key: key, default_value: default_value )
      return opt if opt.nil?
      opt = opt.strip if opt.is_a? String
      opt = to_integer( num: opt ) if opt.is_a? String
      msg_handler.msg_verbose "#{key}='#{opt}'"
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
      msg_handler.msg_verbose "#{key}=[#{opt.join(', ')}]"
      return opt
    end

    def option_path( key:, default_value: nil )
      opt = option_value( key: key, default_value: default_value )
      opt = File.absolute_path opt if opt.present?
      return opt
    end

    def option_value( key:, default_value: nil )
      rv = task_options_value( key: key, default_value: default_value )
      msg_handler.msg_verbose "#{key}=#{rv}" if verbose
      return rv
    end

    def putsf(obj='', *arg)
      puts obj, *arg
      STDOUT.flush
    end

    def readable_sz( size )
      DeepblueHelper.human_readable_size( size )
    end

    def run_email_targets( subject:, body: nil, event: '', event_note: '' )
      body ||= msg_handler_queue_to_html
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

    def test_dates_init
      msg_handler.msg_verbose "Filter date_begin=#{date_begin}"
      msg_handler.msg_verbose "Filter date_end=#{date_end}"
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
