# frozen_string_literal: true

module Deepblue

  require_relative './log_extracter'
  require_relative './log_filter'

  class ProvenanceLogService

    mattr_accessor :provenance_log_service_debug_verbose, default: false

    def self.dissect_entry( line:, error_lines_file:, line_number: )
      line = line.strip
      lines = []
      lines << 'dissect_entry:'
      lines << line
      count = 0
      while line.present?
        count += 1
        if line =~ /^\s*\{(.*)$/
          lines << 'rest:'
          rest = "{#{Regexp.last_match(1)}"
          lines << rest
          begin
            key_values = ProvenanceHelper.parse_log_line_key_values rest
            entry = { timestamp: key_values['timestamp'],
                      event: key_values['event'],
                      raw_key_values: rest }
            event_note = key_values['event_note']
            entry['event_note'] = event_note if event_note.present?
            class_name = key_values['class_name']
            entry['class_name'] = class_name if class_name.present?
            id = key_values['id']
            entry['id'] = id if id.present?
            entry.each_key { |k| lines << "#{k}=#{entry[k]}" }
          rescue Exception => e # rubocop:disable Lint/RescueException
            lines << "ERROR: @#{line_number} - #{e}"
          end
          line = ''
        elsif line =~ /^([^\s]+)\s+(.*)$/
          lines << "part #{count}:"
          lines << "'#{Regexp.last_match(1)}'"
          line = Regexp.last_match(2)
        else
          lines << 'last #{count}:'
          lines << line
          line = ''
        end
      end
      lines << "\n"
      File.write( error_lines_file, lines.join( "\n" ), File.size(error_lines_file), mode: 'a')
    end

    def self.copy_entries_to_db( file_path: nil, skip_existing: true )
      file_path ||= provenance_log_path
      line_number = 0
      lines_encode = 0
      lines_encode_entry = 0
      entries_added = 0
      entries_skipped = 0
      parse_errors = 0
      parse_retry_success = 0
      error_lines_file = "#{file_path}.errors"
      line_was_encoded = false
      File.write( error_lines_file, '' )
      File.open( file_path, "r" ) do |fin|
        until fin.eof?
          begin
            line = fin.readline
            line_number += 1
            newline = line.encode( 'UTF-8', invalid: :replace, undef: :replace )
            if newline != line
              lines_encode += 1
            end
            line = newline
            # line = URI.escape line
            newline = encode_entry( entry: line )
            line_was_encoded = false
            if newline != line
              lines_encode_entry += 1
              line_was_encoded = true
            end
            line = newline
            entry = parse_entry( line, line_number: line_number, parse_key_values: false )
            # write to db
            if entry[:parse_error].present?
              new_entry = parse_entry_retry( line: line, line_number: line_number, parse_key_values: true )
              if new_entry.present?
                parse_retry_success += 1
                db_save_line( line_number: line_number, line: line, entry: new_entry )
                entries_added += 1
              else
                parse_errors += 1
                lines = []
                lines << "parse entry retry failed"
                lines << "line_number: #{line_number}"
                lines << "line_was_encoded: #{line_was_encoded}"
                lines << line
                lines << ""
                File.write( error_lines_file, lines.join( "\n" ), File.size(error_lines_file), mode: 'a')
                puts "ERROR: @#{line_number} - #{entry[:parse_error]}"
                puts "line='#{line}'"
                puts "entry[:raw_key_values]=#{entry[:raw_key_values]}"
              end
             elsif skip_existing
              prov_entry = Provenance.for_timestamp_event( timestamp: entry[:timestamp], event: entry[:event] )
              if prov_entry.blank?
                db_save_line( line_number: line_number, line: line, entry: entry )
                entries_added += 1
              else
                entries_skipped += 1
              end
            else
              begin
                key_values = ProvenanceHelper.parse_log_line_key_values entry[:raw_key_values]
                entry[:raw_key_values] = key_values
                db_save_line( line_number: line_number, line: line, entry: entry )
                entries_added += 1
              rescue Exception => e # rubocop:disable Lint/RescueException
                parse_errors += 1
                puts "ERROR: @#{line_number} - #{e}"
                puts "line='#{line}'"
                puts "entry[:raw_key_values]=#{entry[:raw_key_values]}"
              end
            end
          rescue EOFError
            line = nil
          end
        end
      end
      return { file_path: file_path,
               skip_existing: skip_existing,
               lines: line_number,
               lines_encode: lines_encode,
               lines_encode_entry: lines_encode_entry,
               entries_added: entries_added,
               entries_skipped: entries_skipped,
               parse_errors: parse_errors,
               parse_retry_success: parse_retry_success }
    end

    def self.db_save_line( line_number:, line:, entry: )
      begin
        entry = encode_entry( entry: entry )
        Provenance.new( timestamp: entry[:timestamp],
                        event: entry[:event],
                        event_note: entry[:event_note],
                        class_name: entry[:class_name],
                        cc_id: entry[:id],
                        key_values: entry[:raw_key_values]
        ).save
      rescue ActiveRecord::StatementInvalid => e
        puts "ERROR: @#{line_number} - #{e}"
        puts "line='#{line}'"
      end
    end

    def self.encode_entry( entry: )
      return encode entry if entry.is_a? String
      if entry.respond_to? :keys
        entry.each_key do |k|
          entry[k] = encode_entry( entry: entry[k] )
        end
      elsif entry.respond_to? :map
        entry = entry.map { |x| encode_entry( entry: x ) }
      end
      return entry
    end

    def self.encode( str )
      encoding = Encoding::UTF_8
      ret = case
            when str.ascii_only?
              str
            else
              StringIO.open do |buffer|
                buffer.set_encoding(encoding)
                str.each_codepoint { |u| buffer << encode_unicode(u) }
                buffer.string
              end
            end
      ret.encode(encoding)
    end

    def self.encode_ascii(u)
      case (u = u.ord)
        # when (0x00..0x07) then encode_utf16(u)
        # when (0x0A)       then "\\n"
        # when (0x0D)       then "\\r"
        when (0x0E..0x1F) then encode_utf16(u)
        # when (0x22)       then "\\\""
        # when (0x5C)       then "\\\\"
        when (0x7F)       then encode_utf16(u)
      when (0x00..0x7F) then u.chr
      else
        raise ArgumentError.new("expected an ASCII character in (0x00..0x7F), but got 0x#{u.to_s(16)}")
      end
    end

    def self.encode_unicode(u)
      case (u = u.ord)
      when (0x00..0x7F)        # ASCII 7-bit
        encode_ascii(u)
      when (0x80..0xFFFF)      # Unicode BMP
        encode_utf16(u)
      when (0x10000..0x10FFFF) # Unicode
        encode_utf32(u)
      else
        raise ArgumentError.new("expected a Unicode codepoint in (0x00..0x10FFFF), but got 0x#{u.to_s(16)}")
      end
    end

    # @see http://www.w3.org/TR/rdf-testcases/#ntrip_strings
    def self.encode_utf16(u)
      sprintf("\\u%04X", u.ord)
      # "&u#{u.ord};"
    end

    # @see http://www.w3.org/TR/rdf-testcases/#ntrip_strings
    def self.encode_utf32(u)
      sprintf("\\U%08X", u.ord)
      # "&U#{u.ord};"
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

    def self.key_values_to_table( key_values, parse: false )
      JsonHelper.key_values_to_table( key_values, parse: parse )
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
      new_entry = parse_entry_retry( line: entry, line_number: line_number, parse_key_values: parse_key_values )
      return new_entry if new_entry.present?
      return { entry: entry, line_number: line_number, parse_error: e }
    end

    def self.parse_entry_retry( line:, line_number:, parse_key_values: false )
      entry = {}
      if line =~ /^.*\s+\{(.*)$/
        raw_key_values = Regexp.last_match(1)
        raw_key_values = raw_key_values.strip
        raw_key_values = "{#{raw_key_values}"
        begin
          key_values = ProvenanceHelper.parse_log_line_key_values raw_key_values
          entry[:timestamp] = key_values['timestamp']
          entry[:event] = key_values['event']
          event_note = key_values['event_note']
          entry[:event_note] = event_note if event_note.present?
          class_name = key_values['class_name']
          entry[:class_name] = class_name if class_name.present?
          id = key_values['id']
          entry[:id] = id if id.present?
          if parse_key_values
            entry[:raw_key_values] = key_values
          else
            entry[:raw_key_values] = raw_key_values
          end
          entry.each_key { |k| lines << "#{k}=#{entry[k]}" }
          entry[:line_number] = line_number
          entrt[:parse_error] = nil
        rescue Exception => e # rubocop:disable Lint/RescueException
          entry = { entry: line, line_number: line_number, parse_error: e }
        end
      end
      return entry
    end

    def self.provenance_log_name
      Rails.configuration.provenance_log_name
    end

    def self.provenance_log_path
      Rails.configuration.provenance_log_path
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
