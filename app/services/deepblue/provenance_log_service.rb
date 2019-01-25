# frozen_string_literal: true

module Deepblue

  require 'json'

  require_relative './log_extracter'
  require_relative './log_filter'

  class ProvenanceLogService

    def self.entries( id, refresh: false )
      Deepblue::LoggingHelper.bold_debug "ProvenanceLogService.entries( #{id}, #{refresh} )"
      file_path = Deepblue::ProvenancePath.path_for_reference( id )
      if !refresh && File.exist?( file_path )
        rv = read_entries( file_path )
      else
        rv = filter_entries( id )
        write_entries( file_path, rv )
      end
      Deepblue::LoggingHelper.bold_debug "ProvenanceLogService.entries( #{id} ) read #{rv.size} entries"
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

    def self.pp_key_values( raw_key_values )
      return JSON.pretty_generate( JSON.parse( raw_key_values ) )
    end

    def self.key_values_to_table( key_values, parse: false )
      key_values = JSON.parse( key_values ) if parse
      if key_values.is_a? Array
        case key_values.size
        when 0 then return "<table>\n<tr><td>&nbsp;</td></tr>\n</table>\n"
        when 1 then return "<table>\n<tr><td>#{ERB::Util.html_escape( key_values[0] )}</td></tr>\n</table>\n"
        else
          arr = key_values.map { |x| key_values_to_table( x ) }
          return "<table>\n<tr><td>#{arr.join("</td></tr>\n<tr><td>")}</td></tr>\n</table>\n"
        end
      elsif key_values.is_a? Hash
        rv = "<table>\n"
        key_values.each_pair do |key,value|
          rv += "<tr><td>#{ERB::Util.html_escape( key )}</td><td>#{key_values_to_table( value )}</td></tr>\n"
        end
        rv += "</table>\n"
        return rv
      else
        return ERB::Util.html_escape( key_values )
      end
    end

    def self.read_entries( file_path )
      entries = []
      open( file_path, "r" ) do |fin|
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