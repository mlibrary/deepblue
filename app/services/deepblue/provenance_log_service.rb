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

    def self.entries( id, refresh: false )
      ::Deepblue::LoggingHelper.bold_debug "ProvenanceLogService.entries( #{id}, #{refresh} )" if provenance_log_service_debug_verbose
      file_path = Deepblue::ProvenancePath.path_for_reference( id )
      if !refresh && File.exist?( file_path )
        rv = read_entries( file_path )
      else
        rv = filter_entries( id )
        write_entries( file_path, rv )
      end
      ::Deepblue::LoggingHelper.bold_debug "ProvenanceLogService.entries( #{id} ) read #{rv.size} entries" if provenance_log_service_debug_verbose
      return rv
    end

    def self.filter_entries( id )
      input = Rails.root.join( 'log', "provenance_#{Rails.env}.log" )
      filter = Deepblue::IdLogFilter.new( matching_ids: Array( id ) )
      extractor = Deepblue::LogExtracter.new( filter: filter, input: input )
      extractor.run
      rv = extractor.lines_extracted
      return rv
    end

    def self.parse_entry( entry, line_number: 0 )
      # line is of the form: "timestamp event/event_note/class_name/id key_values"
      timestamp = nil
      event = nil
      event_note = nil
      class_name = nil
      id = nil
      raw_key_values = nil
      timestamp, event, event_note, class_name, id,
          raw_key_values = ProvenanceHelper.parse_log_line( entry, line_number: line_number, raw_key_values: true )
      return { timestamp: timestamp, event: event, event_note: event_note, class_name: class_name, id: id,
               raw_key_values: raw_key_values, line_number: line_number, parse_error: nil }
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