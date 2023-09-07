# frozen_string_literal: true

module Deepblue

  require_relative './log_extracter'
  require_relative './log_filter'

  class ProvenanceLogService

    mattr_accessor :provenance_log_service_debug_verbose, default: false

    def self.provenance_log_name
      Rails.configuration.provenance_log_name
    end

    def self.provenance_log_path
      Rails.configuration.provenance_log_path
    end

    def self.copy_entries_to_db( file_path: nil, skip_existing: true )
      file_path ||= provenance_log_path
      line_number = 0
      File.open( file_path, "r" ) do |fin|
        until fin.eof?
          begin
            line = fin.readline
            line.chop!
            ++line_number
            entry = parse_entry( line, line_number: line_number, parse_key_values: true )
            # write to db
            if entry[:parse_error].present?
              puts "ERROR: @#{line_number} - #{entry[:parse_error]}"
              puts "line='#{line}'"
            else
              entries = Provenance.for_timestamp_event( timestamp: entry[:timestamp], event: entry[:event] )
              if entries.blank?
                Provenance.new( timestamp: entry[:timestamp],
                                event: entry[:event],
                                event_note: entry[:event_note],
                                class_name: entry[:class_name],
                                cc_id: entry[:id],
                                key_values: entry[:raw_key_values]
                ).save
              end
            end
          rescue EOFError
            line = nil
          end
        end
      end
    end

    def self.entries( id, refresh: false, debug_verbose: provenance_log_service_debug_verbose )
      debug_verbose ||= provenance_log_service_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                              ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "refresh=#{refresh}",
                                             "" ] if debug_verbose
      file_path = ::Deepblue::ProvenancePath.path_for_reference( id )
      if !refresh && File.exist?( file_path )
        rv = read_entries( file_path )
      else
        rv = filter_entries( id )
        write_entries( file_path, rv )
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "rv&.size=#{rv&.size}",
                                             "" ] if debug_verbose
      return rv
    end

    def self.entries_filter_by_date_range( id:,
                                           begin_date:,
                                           end_date:,
                                           refresh: false,
                                           debug_verbose: provenance_log_service_debug_verbose )

      debug_verbose ||= provenance_log_service_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "begin_date=#{begin_date}",
                                             "end_date=#{end_date}",
                                             "begin_date.class.name=#{begin_date.class.name}",
                                             "end_date.class.name=#{end_date.class.name}",
                                             "refresh=#{refresh}",
                                             "" ] if debug_verbose

      begin_date = begin_date.beginning_of_day
      end_date = end_date.end_of_day
      entries = entries( id, refresh: refresh, debug_verbose: debug_verbose )
      entries ||= []
      # now filter by date
      rv = entries.select do |entry|
        timestamp = timestamp( entry: entry )
        rv = begin_date <= timestamp && end_date >= timestamp
        # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
        #                                        ::Deepblue::LoggingHelper.called_from,
        #                                        "timestamp=#{timestamp}",
        #                                        "timestamp.class.name=#{timestamp.class.name}",
        #                                        "begin_date <= timestamp: #{begin_date} <= #{timestamp}",
        #                                        "begin_date <= timestamp=#{begin_date <= timestamp}",
        #                                        "end_date <= timestamp: #{end_date} >= #{timestamp}",
        #                                        "end_date <= timestamp=#{end_date >= timestamp}",
        #                                        "select rv=#{rv}",
        #                                        "" ] if debug_verbose
        rv
      end
      rv ||= []
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "rv.size=#{rv.size}",
                                             "" ] if debug_verbose
      return rv
    end

    def self.filter_entries( id )
      input = Rails.root.join( 'log', "provenance_#{Rails.env}.log" )
      filter = ::Deepblue::IdLogFilter.new( matching_ids: Array( id ) )
      extractor = ::Deepblue::LogExtracter.new( filter: filter, input: input )
      extractor.run
      rv = extractor.lines_extracted
      return rv
    end

    def self.parse_entry( entry, line_number: 0, parse_key_values: false )
      # line is of the form: "timestamp event/event_note/class_name/id key_values"
      timestamp = nil
      event = nil
      event_note = nil
      class_name = nil
      id = nil
      raw_key_values = nil
      timestamp,
        event,
        event_note,
        class_name,
        id,
        raw_key_values = ProvenanceHelper.parse_log_line( entry,
                                                          line_number: line_number,
                                                          raw_key_values: !parse_key_values )
      return { timestamp: timestamp,
               event: event,
               event_note: event_note,
               class_name: class_name,
               id: id,
               raw_key_values: raw_key_values,
               line_number: line_number,
               parse_error: nil }
    rescue LogParseError => e
      return { entry: entry, line_number: line_number, parse_error: e }
    end

    def self.key_values_to_table( key_values, parse: false )
      JsonHelper.key_values_to_table( key_values, parse: parse )
    end

    def self.read_entries( file_path )
      entries = []
      File.open( file_path, "r" ) do |fin|
        until fin.eof?
          begin
            line = fin.readline
            line.chop!
            entries << line
          rescue EOFError
            line = nil
          end
        end
      end
      return entries
    end

    def self.timestamp( entry: )
      # debug_verbose = true
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "entry.class.name=#{entry.class.name}",
      #                                        "" ] if debug_verbose
      return nil if entry.blank?
      entry = entry.first if entry.is_a? Array
      entry = parse_entry entry if entry.is_a? String
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "entry=#{entry.pretty_inspect}",
      #                                        "" ] if debug_verbose
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "entry[:timestamp].class.name=#{entry[:timestamp].class.name}",
      #                                        "" ] if debug_verbose
      return nil if entry[:timestamp].blank?
      timestamp_str = entry[:timestamp]
      ::Deepblue::JsonLoggerHelper.parse_timestamp timestamp_str
    end

    def self.write_entries( file_path, entries )
      # file_path = Pathname.new file_path unless file_path.is_a? Pathname
      dir = File.dirname file_path
      FileUtils.mkpath dir unless Dir.exist? dir
      File.open( file_path, "w" ) do |out|
        entries.each { |line| out.puts line }
      end
    end

  end

end
