# frozen_string_literal: true

module Deepblue

  class ZipContentsService

    mattr_accessor :zip_contents_service_debug_verbose, default: false

    def self.entries( id, refresh: false )
      debug_verbose = zip_contents_service_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "refresh=#{refresh}",
                                             "" ] if debug_verbose
      file_path = ZipContentsPath.path_for_reference( id )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "file_path=#{file_path}",
                                             "" ] if debug_verbose
      if !refresh && File.exist?( file_path )
        rv = read_entries( file_path )
      else
        rv = load_entries( id )
        write_entries( file_path, rv )
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "entries read=#{rv.size}",
                                             "" ] if debug_verbose
      return rv
    end

    def self.load_entries( id )
      debug_verbose = zip_contents_service_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "" ] if debug_verbose
      file_set = PersistHelper.find( id )
      file = file_set.files_to_file
      return ["file set #{id} files_to_file returned nil"] if file.nil?
      source_uri = file.uri.value
      entries = ZipHelper.zip_table_of_contents_uri( source_uri, line_prefix: '+', verbose: debug_verbose )
      return entries
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
      debug_verbose = zip_contents_service_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "file_path=#{file_path}",
                                             "" ] if debug_verbose
      dir = File.dirname file_path
      FileUtils.mkpath dir unless Dir.exist? dir
      File.open( file_path, "w" ) do |out|
        entries.each { |line| out.puts line }
      end
    end

  end

end