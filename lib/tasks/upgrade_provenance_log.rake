# frozen_string_literal: true

require_relative './task_reporter'
require_relative '../../app/models/concerns/deepblue/abstract_event_behavior'

namespace :deepblue do

  # bundle exec rake deepblue:upgrade_provenance_log[log/p-20180613-provenance.log,log/p-20180613-provenance-out.log,log/p-20180613-provenance-report.log]
  # bundle exec rake deepblue:upgrade_provenance_log[log/p-20180613a-provenance.log,log/p-20180613a-provenance-out.log,log/p-20180613a-provenance-report.log]
  desc 'Upgrade provenance log'
  # See: https://stackoverflow.com/questions/825748/how-to-pass-command-line-arguments-to-a-rake-task
  task :upgrade_provenance_log, %i[input_file output_file report_file] => :environment do |_task, args|
    # puts "upgrade_provenance_log", args.as_json
    task = Deepblue::UpgradeProvenanceLog.new( input_file: args[:input_file],
                                               output_file: args[:output_file],
                                               report_file: args[:report_file] )
    task.run
    task.report_results( to_this: STDOUT )
    task.report_results
  end

end

module Deepblue

  class ProvenanceLogRecord

    attr_accessor :class_name, :event, :event_note, :id, :timestamp
    attr_accessor :json_encode
    attr_accessor :input_line_number, :output_line_number
    attr_accessor :added_prov_key_values

    def initialize( class_name:,
                    event:,
                    event_note:,
                    id:,
                    timestamp:,
                    user_email: '',
                    input_line_number:,
                    json_encode: true,
                    **added_prov_key_values )

      @class_name = class_name
      @event = event
      @event_note = event_note
      @id = id
      @timestamp = timestamp
      @user_email = user_email
      @input_line_number = input_line_number
      @output_line_number = nil
      @json_encode = json_encode
      @added_prov_key_values = added_prov_key_values
    end

    def msg_to_log
      prov_key_values = ProvenanceHelper.initialize_prov_key_values( user_email: @user_email,
                                                                     event_note: @event_note,
                                                                     **@added_prov_key_values )
      msg = ProvenanceHelper.msg_to_log( class_name: @class_name,
                                         event: @event,
                                         event_note: @event_note,
                                         id: @id,
                                         timestamp: @timestamp,
                                         json_encode: @json_encode,
                                         **prov_key_values )
      msg
    end

  end

  class UpgradeProvenanceLog
    include TaskReporter
    include AbstractEventBehavior

    attr_reader :error_line_numbers, :error_output_line_numbers, :input_line_number, :last_error, :output_line_number

    class ParseError < RuntimeError
    end

    RE_VISIBILITY = '(open|restricted)'

    RE_ADMIN_SET_ID = 'admin set id: (.*)'
    RE_BY_CREATORS = 'by (.+)'
    RE_BY_PLUS_CREATORS = 'by \+ (.+)'
    RE_CONTENT_TYPE = 'content type: (.*)'
    RE_DESCRIPTION = 'description: (.*)'
    RE_EMAIL = '((?:[a-zA-Z0-9_\-\.]+)@(?:[a-zA-Z0-9_\-\.]+)\.(?:[a-zA-Z]{2,5}))'
    RE_ID = 'id: ([a-z0-9]+)'
    RE_ID2 = '([a-z0-9]+)'
    RE_LINK_GENERIC_WORK = '\(https?:\/\/deepblue\.lib\.umich\.edu\/data\/concern\/generic_works\/([a-z0-9]+)(?:\?locale=en)?\)'
    RE_METHODOLOGY = 'methodology: (.*)'
    RE_ON = 'on: (\d\d\d\d\-.*)'
    RE_ORIGINAL_NAME = 'original name: (.*)'
    RE_PARENT_ID = 'parent[ _]id: ([a-z0-9]+)'
    RE_PUBLISHER = 'publisher: (.*)'
    RE_REST = '(.*)'
    RE_RIGHTS = 'rights: (.*)'
    RE_SIZE = '(\d*)'
    RE_START_DATE = '(\d\d\d\d\-\d\d\-\d\d \d\d:\d\d:\d\d)'
    RE_SUBJECT = 'subject: (.*)'
    RE_TITLE = 'title: (.*)'
    RE_TITLE_FIRST = '(.+)'
    RE_TOTAL_SIZE = 'total size: (\d*)'
    RE_VALUE = '([^:,]*)'
    RE_WITH_ACCESS = "with #{RE_VISIBILITY} access"

    RE_DISCARD_DOI_CANNOT_BE_MINTED = 'DOI cannot be minted for a work without files.'
    RE_DISCARD_OPEN_TO_OPEN_ACCESS = ".+#{RE_LINK_GENERIC_WORK} #{RE_BY_PLUS_CREATORS} with open access was previously deposited by #{RE_EMAIL}, was updated to open access"
    RE_DISCARD_GLOBUS_CLEAN = ".+#{RE_LINK_GENERIC_WORK} #{RE_BY_PLUS_CREATORS} with #{RE_VISIBILITY} cleaned Globus directories"

    SPLITTER_TICK_COMMA_TICK = "','"
    SPLITTER_NEWLINES = "\\n\\n"
    SPLITTER_SEMICOLON_SPACE = '; '
    SPLITTER_CREATOR = [ SPLITTER_TICK_COMMA_TICK, SPLITTER_SEMICOLON_SPACE ].freeze
    SPLITTER_SUBJECT = [ SPLITTER_TICK_COMMA_TICK, SPLITTER_SEMICOLON_SPACE ].freeze
    SPLITTER_TITLE = [ SPLITTER_TICK_COMMA_TICK, SPLITTER_SEMICOLON_SPACE ].freeze

    def initialize( input_file:, output_file:, report_file:, output_mode: "w" )
      @input_file = input_file
      @output_file = output_file
      @report_file = report_file
      @output_mode = output_mode
      @prov_log_upgraded = "prov log upgrade #{ProvenanceHelper.timestamp_now}".tr( ' ', '_' )
      @last_error = nil

      # flags
      @fix_backslashes = true
      @pacifier_active = false
      @inspect_report_to_stdout = true

      # @log_level = Logger::DEBUG
      @log_level = Logger::INFO
      @error_line_number_count_to_display = 10

      @re_discard = Regexp.compile( "^(#{RE_DISCARD_DOI_CANNOT_BE_MINTED}|#{RE_DISCARD_OPEN_TO_OPEN_ACCESS}|#{RE_DISCARD_GLOBUS_CLEAN})$" )

      @re_record_start = Regexp.compile( "^#{RE_START_DATE} INFO User:  #{RE_REST}$" )
      @re_doi_kicked_off = Regexp.compile( "^DOI process kicked off for work #{RE_ID}$")
      # DOI cannot be minted for a work without files.
      @re_file_uploaded = Regexp.compile( "^File Uploaded with #{RE_PARENT_ID}, #{RE_TOTAL_SIZE}," +
                                          " #{RE_ORIGINAL_NAME}, #{RE_CONTENT_TYPE}$" )
      @re_migrate_export_collection = Regexp.compile( "^Migrate export Collection #{RE_ID2}$" )
      @re_migrate_export_file_set = Regexp.compile( "^Migrate export FileSet #{RE_ID2} #{RE_PARENT_ID}$" )
      @re_migrate_export_work = Regexp.compile( "^Migrate export GenericWork #{RE_ID2}( #{RE_PARENT_ID})?$" )
      @re_work_created = Regexp.compile( "^WORK CREATED: #{RE_LINK_GENERIC_WORK} #{RE_BY_CREATORS}, #{RE_WITH_ACCESS}" +
                                         " was created with #{RE_TITLE}, #{RE_RIGHTS}, #{RE_METHODOLOGY}," +
                                         " #{RE_PUBLISHER}, #{RE_SUBJECT}, #{RE_DESCRIPTION}, #{RE_ADMIN_SET_ID}$" )
      @re_work_created2 = Regexp.compile( "^WORK Created: #{RE_LINK_GENERIC_WORK} #{RE_BY_PLUS_CREATORS} #{RE_WITH_ACCESS} was created #{RE_TITLE}$" )
      @re_work_created_or_updated = Regexp.compile( "^WORK (CREATED|Created|UPDATED|Updated): #{RE_LINK_GENERIC_WORK}#{RE_REST}$" )
      @re_work_created3 = Regexp.compile( "^#{RE_TITLE_FIRST} #{RE_LINK_GENERIC_WORK} #{RE_BY_PLUS_CREATORS} #{RE_WITH_ACCESS} was created$" )
      @re_work_deleted = Regexp.compile( "^#{RE_TITLE_FIRST} #{RE_LINK_GENERIC_WORK} #{RE_BY_PLUS_CREATORS} #{RE_WITH_ACCESS} was deleted from the system$" )
      @re_work_published = Regexp.compile( "^#{RE_TITLE_FIRST} #{RE_LINK_GENERIC_WORK} #{RE_BY_CREATORS}, previously" +
                                           " deposited by #{RE_EMAIL}, was updated to open access$" )
      @re_work_updated = Regexp.compile( "^WORK UPDATED: #{RE_LINK_GENERIC_WORK} #{RE_BY_CREATORS}, #{RE_WITH_ACCESS}" +
                                         " was updated with #{RE_TITLE}, #{RE_ON}, #{RE_RIGHTS}, #{RE_METHODOLOGY}," +
                                         " #{RE_PUBLISHER}, #{RE_SUBJECT}, #{RE_DESCRIPTION}, #{RE_ADMIN_SET_ID}$" )
      # WORK Updated: (http://deepblue.lib.umich.edu/data/concern/generic_works/wm117p52g) by + Regoli, Leonardo H. with restricted access was updated title: Model outputs for "Multi-species and multi-fluid MHD approaches for the study of ionospheric escape at Mars" on: 2018-04-04T14:45:35+00:00
      @re_work_updated2 = Regexp.compile( "^WORK Updated: #{RE_LINK_GENERIC_WORK} #{RE_BY_PLUS_CREATORS} #{RE_WITH_ACCESS} was updated #{RE_TITLE} #{RE_ON}$" )
    end

    def report_results( to_this: nil )
      if to_this.nil?
        open( @report_file, "w" ) { |fout| report_results( to_this: fout ) }
        return
      end
      to_this.puts
      to_this.puts "#{self.class.name} report"
      to_this.puts "lines processed: #{@input_line_number}"
      to_this.puts "records written: #{@output_line_number}"
      to_this.puts "records with values to inspect: #{@records_to_inspect_count}"
      if @parse_error_input_line_numbers.size.positive?
        to_this.puts "parse errors: #{@parse_error_input_line_numbers.size}"
        if @error_line_number_count_to_display < @parse_error_input_line_numbers.size
          max_range = @error_line_number_count_to_display - 1
          to_this.puts "parse error input line numbers: #{@parse_error_input_line_numbers[0..max_range]}"
          to_this.puts "parse error output line numbers: #{@parse_error_output_line_numbers[0..max_range]}"
        else
          to_this.puts "parse error input line numbers: #{@parse_error_input_line_numbers}"
          to_this.puts "parse error output line numbers: #{@parse_error_output_line_numbers}"
        end
      end
      return if @records_to_inspect_count.zero?
      return unless @inspect_report_to_stdout
      @record_values_to_inspect.each { |x| to_this.puts x.to_s }
    end

    def run
      log.level = @log_level
      pacifier.active = @pacifier_active
      log.debug "#{self.class.name}.run"
      log.debug "input_file=#{@input_file} (#{@input_file.class.name})"
      log.debug "output_file=#{@output_file}"
      return unless valid_input_file
      return unless valid_output_file
      @output_log = nil
      @output_line_number = 0
      @parse_error_input_line_numbers = []
      @parse_error_output_line_numbers = []
      @records_to_inspect_count = 0
      @record_values_to_inspect = []
      begin
        @output_log = open( @output_file, @output_mode )
        @input_line_buffer = nil
        @input_line_buffer_start_line_number = nil
        @input_line_number = 0
        @output_record = nil
        open( @input_file, "r" ) do |fin|
          until fin.eof?
            pacifier.pacify
            read_input_line fin
            record_process
          end
        end
        @input_line = nil
        # process last record
        record_process
      ensure
        pacifier.nl
        @output_log.flush unless @output_log.nil? # rubocop:disable Style/SafeNavigation
        @output_log.close unless @output_log.nil? # rubocop:disable Style/SafeNavigation
      end
    end

    protected

      def error_report
        log.error @last_error if @last_error.present?
      end

      def fix_backslashes( key:, value: )
        return value unless @fix_backslashes
        # rubocop:disable Lint/EmptyWhen
        case key.to_s
        when 'methodology'
          # fix
        when 'description'
          # fix
        when 'title'
          # fix
        else
          return value
        end
        # rubocop:enable Lint/EmptyWhen
        value.gsub( '\\\\', '\\' )
      end

      def fix_property_value( properties:, key:, value:, splitter: )
        key = key.to_s
        return fix_backslashes( key: key, value: value ) unless properties.key? key
        property = properties[key]
        return fix_backslashes( key: key, value: value ) unless property.multiple?
        return [fix_backslashes( key: key, value: value )] if splitter.nil?
        new_value = fix_property_value_split( value: value, splitter: splitter )
        return [fix_backslashes( key: key, value: value )] if new_value == value
        return [fix_backslashes( key: key, value: new_value )] unless new_value.is_a? Array
        new_value = new_value.map { |v| fix_backslashes( key: key, value: v ) }
        new_value
      end

      def fix_property_value_split( value:, splitter: )
        if splitter.is_a? String
          return value unless value.include? splitter
          return value.split( splitter )
        end
        return value unless splitter.is_a? Array
        splitter.each do |sp|
          next unless value.include? sp
          return value.split( sp )
        end
        value
      end

      def fix_property_value_data_set( key:, value:, splitter: nil )
        fix_property_value( properties: DataSet.properties, key: key, value: value, splitter: splitter )
      end

      def fix_property_value_file_set( key:, value:, splitter: nil )
        fix_property_value( properties: FileSet.properties, key: key, value: value, splitter: splitter )
      end

      def human_readable( value )
        return '' if value.nil?
        value = value.to_i if value.is_a? String
        ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert( value, precision: 3 )
      end

      def inspect_record_values
        return if @output_record.nil?
        added_prov_key_values = @output_record.added_prov_key_values
        values_to_inspect_count = 0
        added_prov_key_values.each_pair do |key, value|
          value = value.to_s
          if inspect_colon_key?( key ) && value.include?( ':' )
            values_to_inspect_count += 1
            # pacifier.pacify ':'
            # pacifier.pacify_bracket "#{key},#{value}"
            add_inspect_record_value( found: 'colon', key: key, value: value )
          end
          if value.include? ';'
            values_to_inspect_count += 1
            add_inspect_record_value( found: 'semicolon', key: key, value: value )
          end
          if value.include? "','"
            values_to_inspect_count += 1
            add_inspect_record_value( found: 'tick-comma-tick', key: key, value: value )
          end
        end
        @records_to_inspect_count += 1 if values_to_inspect_count.positive?
      end

      def add_inspect_record_value( found:, key:, value: )
        @record_values_to_inspect << [ found,
                                       [ @output_record.input_line_number, @output_line_number ],
                                       [ @output_record.event, @output_record.class_name, @output_record.id ],
                                       key,
                                       value ]
      end

      def inspect_colon_key?( key )
        return case key.to_s
               when 'on'
                 false
               when 'record_date'
                 false
               when 'rights_license'
                 false
               when 'timestamp'
                 false
               else
                 true
               end
      end

      def invalid( error_msg:, rv: false )
        @last_error = error_msg
        rv
      end

      def read_input_line( fin )
        @input_line = fin.readline
        @input_line.chop!
        @input_line.gsub!( '\\', '\\\\' )
        @input_line_number += 1
      rescue EOFError
        pacifier.pacify '!'
        @input_line = nil
        @last_error = "EOFError"
      end

      def record_parse
        pacifier.pacify 'p'
        match = @re_record_start.match @input_line_buffer
        raise ParseError "Expected start of record at line #{@input_line_buffer_start_line_number}" unless match
        record_date = match[1]
        rest = match[2]
        if @re_discard.match rest # rubocop:disable Performance/RegexpMatch
          record_parse_discard
          return
        end
        if @re_work_created_or_updated.match rest # rubocop:disable Performance/RegexpMatch
          return if record_parse_work_created( record_date: record_date, match: @re_work_created.match( rest ) )
          return if record_parse_work_created2( record_date: record_date, match: @re_work_created2.match( rest ) )
          return if record_parse_work_updated( record_date: record_date, match: @re_work_updated.match( rest ) )
          return if record_parse_work_updated2( record_date: record_date, match: @re_work_updated2.match( rest ) )
          record_parse_failed( record_date: record_date, rest: rest )
          return
        end
        return if record_parse_doi_kicked_off( record_date: record_date, match: @re_doi_kicked_off.match( rest ) )
        return if record_parse_file_upload( record_date: record_date, match: @re_file_uploaded.match( rest ) )
        return if record_parse_migrate_export_collection( record_date: record_date, match: @re_migrate_export_collection.match( rest ) )
        return if record_parse_migrate_export_file_set( record_date: record_date, match: @re_migrate_export_file_set.match( rest ) )
        return if record_parse_migrate_export_work( record_date: record_date, match: @re_migrate_export_work.match( rest ) )
        return if record_parse_work_created3( record_date: record_date, match: @re_work_created3.match( rest ) )
        return if record_parse_work_deleted( record_date: record_date, match: @re_work_deleted.match( rest ) )
        return if record_parse_work_published( record_date: record_date, match: @re_work_published.match( rest ) )
        record_parse_failed( record_date: record_date, rest: rest )
      end

      def record_parse_doi_kicked_off( record_date:, match: )
        return false unless match
        pacifier.pacify_bracket 'DOI'
        timestamp = ProvenanceHelper.to_log_format_timestamp record_date
        id = match[1]
        @output_record = ProvenanceLogRecord.new( class_name: 'DataSet',
                                                  event: EVENT_MINT_DOI,
                                                  event_note: @prov_log_upgraded,
                                                  id: id,
                                                  timestamp: timestamp,
                                                  input_line_number: @input_line_number - 1 )
        true
      end

      def record_parse_discard
        pacifier.pacify '<D>'
      end

      def record_parse_failed( record_date:, rest: )
        pacifier.pacify '<<F>>'
        timestamp = ProvenanceHelper.to_log_format_timestamp record_date
        @output_record = ProvenanceLogRecord.new( class_name: 'UNKNOWN',
                                                  event: 'PARSE_FAILED',
                                                  event_note: @prov_log_upgraded,
                                                  id: 'UNKNOWN',
                                                  timestamp: timestamp,
                                                  input_line_number: @input_line_number - 1,
                                                  json_encode: false,
                                                  line_number: @input_line_number,
                                                  record_date: record_date,
                                                  rest: rest )
      end

      def record_parse_file_upload( record_date:, match: )
        return false unless match
        pacifier.pacify_bracket 'FU'
        timestamp = ProvenanceHelper.to_log_format_timestamp record_date
        id = match[1]
        file_size = fix_property_value_file_set( key: :file_size, value: match[2] )
        file_size_human_readable = fix_property_value_file_set( key: :file_size_human_readable,
                                                                value: human_readable( file_size ) )
        original_name = fix_property_value_file_set( key: :original_name, value: match[3] )
        mime_type = fix_property_value_file_set( key: :mime_type, value: match[4] )
        @output_record = ProvenanceLogRecord.new( class_name: 'FileSet',
                                                  event: EVENT_UPLOAD,
                                                  event_note: @prov_log_upgraded,
                                                  id: id,
                                                  timestamp: timestamp,
                                                  input_line_number: @input_line_number - 1,
                                                  file_size: file_size,
                                                  file_size_human_readable: file_size_human_readable,
                                                  mime_type: mime_type,
                                                  original_name: original_name )
        true
      end

      def record_parse_migrate_export_collection( record_date:, match: )
        return false unless match
        pacifier.pacify_bracket 'MC'
        timestamp = ProvenanceHelper.to_log_format_timestamp record_date
        collection_id = match[1]
        @output_record = ProvenanceLogRecord.new( class_name: 'Collection',
                                                  event: EVENT_MIGRATE,
                                                  event_note: "export",
                                                  id: collection_id,
                                                  timestamp: timestamp,
                                                  input_line_number: @input_line_number - 1 )
        true
      end

      def record_parse_migrate_export_file_set( record_date:, match: )
        return false unless match
        pacifier.pacify_bracket 'MFS'
        timestamp = ProvenanceHelper.to_log_format_timestamp record_date
        file_set_id = match[1]
        parent_id = match[2]
        @output_record = ProvenanceLogRecord.new( class_name: 'FileSet',
                                                  event: EVENT_MIGRATE,
                                                  event_note: "export",
                                                  id: file_set_id,
                                                  parent_id: parent_id,
                                                  timestamp: timestamp,
                                                  input_line_number: @input_line_number - 1 )
        true
      end

      def record_parse_migrate_export_work( record_date:, match: )
        return false unless match
        pacifier.pacify_bracket 'MW'
        timestamp = ProvenanceHelper.to_log_format_timestamp record_date
        work_id = match[1]
        parent_id = match[3] if match.size > 2
        if parent_id.present?
          @output_record = ProvenanceLogRecord.new( class_name: 'DataSet',
                                                    event: EVENT_MIGRATE,
                                                    event_note: "export",
                                                    id: work_id,
                                                    parent_id: parent_id,
                                                    timestamp: timestamp,
                                                    input_line_number: @input_line_number - 1 )
        else
          @output_record = ProvenanceLogRecord.new( class_name: 'DataSet',
                                                    event: EVENT_MIGRATE,
                                                    event_note: "export",
                                                    id: work_id,
                                                    timestamp: timestamp,
                                                    input_line_number: @input_line_number - 1 )
        end
        true
      end

      def record_parse_work_created( record_date:, match: )
        return false unless match
        pacifier.pacify_bracket 'WC'
        timestamp = ProvenanceHelper.to_log_format_timestamp record_date
        id = match[1]
        creator = fix_property_value_data_set( key: :creator, value: match[2], splitter: SPLITTER_CREATOR )
        visibility = fix_property_value_data_set( key: :visibility, value: match[3] )
        title = fix_property_value_data_set( key: :title, value: match[4], splitter: SPLITTER_TITLE )
        rights_license = fix_property_value_data_set( key: :rights_license, value: match[5] )
        methodology = fix_property_value_data_set( key: :methodology, value: match[6] )
        publisher = fix_property_value_data_set( key: :publisher, value: match[7] )
        subject_discipline = fix_property_value_data_set( key: :subject_discipline,
                                                          value: match[8],
                                                          splitter: SPLITTER_SUBJECT )
        description = fix_property_value_data_set( key: :description, value: match[9], splitter: SPLITTER_NEWLINES )
        admin_set_id = fix_property_value_data_set( key: :admin_set_id, value: match[10] )
        @output_record = ProvenanceLogRecord.new( class_name: 'DataSet',
                                                  event: EVENT_CREATE,
                                                  event_note: @prov_log_upgraded,
                                                  id: id,
                                                  timestamp: timestamp,
                                                  input_line_number: @input_line_number - 1,
                                                  admin_set_id: admin_set_id,
                                                  creator: creator,
                                                  description: description,
                                                  methodology: methodology,
                                                  publisher: publisher,
                                                  rights_license: rights_license,
                                                  subject_discipline: subject_discipline,
                                                  title: title,
                                                  visibility: visibility )
        true
      end

      def record_parse_work_created2( record_date:, match: )
        return false unless match
        pacifier.pacify_bracket 'WC'
        timestamp = ProvenanceHelper.to_log_format_timestamp record_date
        id = match[1]
        creator = fix_property_value_data_set( key: :creator, value: match[2], splitter: SPLITTER_CREATOR )
        visibility = fix_property_value_data_set( key: :visibility, value: match[3] )
        title = fix_property_value_data_set( key: :title, value: match[4], splitter: SPLITTER_TITLE )
        @output_record = ProvenanceLogRecord.new( class_name: 'DataSet',
                                                  event: EVENT_CREATE,
                                                  event_note: @prov_log_upgraded,
                                                  id: id,
                                                  timestamp: timestamp,
                                                  input_line_number: @input_line_number - 1,
                                                  creator: creator,
                                                  title: title,
                                                  visibility: visibility )
        true
      end

      def record_parse_work_created3( record_date:, match: )
        return false unless match
        pacifier.pacify_bracket 'WD'
        timestamp = ProvenanceHelper.to_log_format_timestamp record_date
        title = fix_property_value_data_set( key: :title, value: match[1], splitter: SPLITTER_TITLE )
        id = match[2]
        creator = fix_property_value_data_set( key: :creator, value: match[3], splitter: SPLITTER_CREATOR )
        visibility = fix_property_value_data_set( key: :visibility, value: match[4] )
        @output_record = ProvenanceLogRecord.new( class_name: 'DataSet',
                                                  event: EVENT_CREATE,
                                                  event_note: @prov_log_upgraded,
                                                  id: id,
                                                  timestamp: timestamp,
                                                  input_line_number: @input_line_number - 1,
                                                  creator: creator,
                                                  title: title,
                                                  visibility: visibility )
        true
      end

      def record_parse_work_deleted( record_date:, match: )
        return false unless match
        pacifier.pacify_bracket 'WD'
        timestamp = ProvenanceHelper.to_log_format_timestamp record_date
        title = fix_property_value_data_set( key: :title, value: match[1], splitter: SPLITTER_TITLE )
        id = match[2]
        creator = fix_property_value_data_set( key: :creator, value: match[3], splitter: SPLITTER_CREATOR )
        visibility = fix_property_value_data_set( key: :visibility, value: match[4] )
        @output_record = ProvenanceLogRecord.new( class_name: 'DataSet',
                                                  event: EVENT_DESTROY,
                                                  event_note: @prov_log_upgraded,
                                                  id: id,
                                                  timestamp: timestamp,
                                                  input_line_number: @input_line_number - 1,
                                                  creator: creator,
                                                  title: title,
                                                  visibility: visibility )
        true
      end

      def record_parse_work_published( record_date:, match: )
        return false unless match
        pacifier.pacify_bracket 'WP'
        timestamp = ProvenanceHelper.to_log_format_timestamp record_date
        title = fix_property_value_data_set( key: :title, value: match[1], splitter: SPLITTER_TITLE )
        id = match[2]
        creator = fix_property_value_data_set( key: :creator, value: match[3], splitter: SPLITTER_CREATOR )
        user_email = match[4]
        visibility = fix_property_value_data_set( key: :visibility, value: 'open' )
        @output_record = ProvenanceLogRecord.new( class_name: 'DataSet',
                                                  event: EVENT_PUBLISH,
                                                  event_note: @prov_log_upgraded,
                                                  id: id,
                                                  timestamp: timestamp,
                                                  user_email: user_email,
                                                  input_line_number: @input_line_number - 1,
                                                  creator: creator,
                                                  title: title,
                                                  visibility: visibility )
        true
      end

      def record_parse_work_updated( record_date:, match: )
        return false unless match
        pacifier.pacify_bracket 'WU'
        # pacifier.pacify_bracket "record_date=#{record_date}"
        # pacifier.pacify_bracket "id=#{match[1]}"
        timestamp = ProvenanceHelper.to_log_format_timestamp record_date
        id = match[1]
        creator = fix_property_value_data_set( key: :creator, value: match[2], splitter: SPLITTER_CREATOR )
        visibility = fix_property_value_data_set( key: :visibility, value: match[3] )
        title = fix_property_value_data_set( key: :title, value: match[4], splitter: SPLITTER_TITLE )
        on = match[5]
        rights_license = fix_property_value_data_set( key: :rights_license, value: match[6] )
        methodology = fix_property_value_data_set( key: :methodology, value: match[7] )
        publisher = fix_property_value_data_set( key: :publisher, value: match[8] )
        subject_discipline = fix_property_value_data_set( key: :subject_discipline,
                                                          value: match[9],
                                                          splitter: SPLITTER_SUBJECT )
        description = fix_property_value_data_set( key: :description, value: match[10], splitter: SPLITTER_NEWLINES )
        admin_set_id = fix_property_value_data_set( key: :admin_set_id, value: match[11] )
        @output_record = ProvenanceLogRecord.new( class_name: 'DataSet',
                                                  event: EVENT_UPDATE,
                                                  event_note: @prov_log_upgraded,
                                                  id: id,
                                                  timestamp: timestamp,
                                                  input_line_number: @input_line_number - 1,
                                                  admin_set_id: admin_set_id,
                                                  description: description,
                                                  creator: creator,
                                                  methodology: methodology,
                                                  on: on,
                                                  publisher: publisher,
                                                  rights_license: rights_license,
                                                  subject_discipline: subject_discipline,
                                                  title: title,
                                                  visibility: visibility )
        true
      end

      def record_parse_work_updated2( record_date:, match: )
        return false unless match
        pacifier.pacify_bracket 'WC'
        timestamp = ProvenanceHelper.to_log_format_timestamp record_date
        id = match[1]
        creator = fix_property_value_data_set( key: :creator, value: match[2], splitter: SPLITTER_CREATOR )
        visibility = fix_property_value_data_set( key: :visibility, value: match[3] )
        title = fix_property_value_data_set( key: :title, value: match[4], splitter: SPLITTER_TITLE )
        on = fix_property_value_data_set( key: :on, value: match[5] )
        @output_record = ProvenanceLogRecord.new( class_name: 'DataSet',
                                                  event: EVENT_UPDATE,
                                                  event_note: @prov_log_upgraded,
                                                  id: id,
                                                  timestamp: timestamp,
                                                  input_line_number: @input_line_number - 1,
                                                  creator: creator,
                                                  on: on,
                                                  title: title,
                                                  visibility: visibility )
        true
      end

      def record_process
        if @input_line_buffer.nil?
          pacifier.pacify '+'
          @input_line_buffer = @input_line
          @input_line_buffer_start_line_number = @input_line_number
        elsif @input_line.nil?
          pacifier.pacify 'L'
          # pacifier.pacify_bracket "output_record=#{@input_line_buffer}"
          # last record to process
          record_parse
          record_write
          @input_line_buffer = nil
          @input_line_buffer_start_line_number = nil
        elsif record_start?( @input_line )
          pacifier.pacify 's'
          record_parse
          record_write
          @input_line_buffer = @input_line
          @input_line_buffer_start_line_number = @input_line_number
        else
          pacifier.pacify '@'
          @input_line_buffer << "\\n#{@input_line}"
        end
      end

      def record_start?( line )
        # pacifier.pacify_bracket line
        rv = @re_record_start.match line
        rv.present?
      end

      def record_write
        return if @output_record.nil?
        pacifier.pacify 'w'
        @output_line_number += 1
        inspect_record_values
        if 'PARSE_FAILED' == @output_record.event
          added_prov_key_values = @output_record.added_prov_key_values
          line_number = added_prov_key_values[:line_number] - 1
          @parse_error_input_line_numbers << line_number
          @parse_error_output_line_numbers << @output_line_number
          msg = ">>>>> (#{line_number}) #{added_prov_key_values[:record_date]} #{added_prov_key_values[:rest]}"
        else
          msg = @output_record.msg_to_log
        end
        @output_log.puts msg.to_s
        @output_record = nil
      end

      def valid_input_file
        @input_file = File.absolute_path( @input_file )
        return invalid( error_msg: "input file is a directory" ) if File.directory? @input_file
        File.exist? @input_file
      end

      def valid_output_file
        @output_file = File.absolute_path( @output_file )
        return true unless File.exist? @output_file
        return invalid( error_msg: "output file is a directory" ) if File.directory? @output_file
        return invalid( error_msg: "output file is not writable" ) unless File.writable? @output_file
        true
      end

  end

end
