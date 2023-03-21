# frozen_string_literal: true

module ZipHelper

  require 'down'
  require 'zip'

  def self.zip_depth( name )
    depth = name.count( '/' )
    return 0 if depth.blank? || depth == 0
    return depth - 1 if name.end_with? '/'
    return depth
  end

  def self.zip_max_depth( names )
    max_depth = 0
    names.each do |name|
      depth = zip_depth( name )
      max_depth = depth if depth > max_depth
    end
    return max_depth
  end

  def self.zip_skip_entry?( entry_name )
    return true if entry_name.start_with? '__MACOSX/'
    return true if entry_name.end_with? '.DS_Store'
    return false
  end

  def self.zip_names_from_file( file, zip_names: [] )
    Zip::File.open( file ) do |zip|
      zip.each do |zip_entry|
        zip_names << zip_entry.name
      end
    end
    return zip_names
  end

  def self.zip_names_from_uri( source_uri, zip_names: [], verbose: false )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "source_uri=#{source_uri}",
                                           "" ] if verbose
    # Down.open( source_uri ) do |source|
    #   Zip::InputStream.open( source ) do |zip|
    #     sleep 1 until zip_entry = zip.get_next_entry
    #     zip_names << zip_entry.name
    #     # zip.each do |zip_entry|
    #     #   zip_names << zip_entry.name
    #     # end
    #   end
    # end
    open( source_uri ) do |source|
      Zip::InputStream.open( source ) do |zip|
        loop do
          sleep 0.1 until ( zip_entry = zip.get_next_entry || zip.eof )
          break if zip.eof
          zip_names << zip_entry.name
        end
      end
    end
    return zip_names
  end

  def self.zip_table_of_contents( zip_file, line_prefix: '+', verbose: false )
    zip_names = zip_names_from_file( zip_file )
    zip_table_of_contents2( zip_names, line_prefix: line_prefix, verbose: verbose )
  end

  def self.zip_table_of_contents_uri( source_uri, line_prefix: '+', verbose: false )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "source_uri=#{source_uri}",
                                           "line_prefix=#{line_prefix}",
                                           "" ] if verbose
    zip_names = zip_names_from_uri( source_uri, verbose: verbose )
    zip_table_of_contents2( zip_names, line_prefix: line_prefix, verbose: verbose )
  end

  def self.zip_table_of_contents2( zip_names, line_prefix: '+', verbose: false )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "zip_names.size=#{zip_names.size}",
                                           "line_prefix=#{line_prefix}",
                                           "" ] if verbose
    prefix_stack = []
    zip_names.sort!
    zip_names.reverse!
    lines = []
    while ( !zip_names.empty? ) do
      name = zip_names.pop
      next if zip_skip_entry? name
      depth = zip_depth( name )
      prefix = prefix_stack.empty? ? '' : prefix_stack.last # top of stack
      pname = name
      #lines << "prefix=#{prefix}" if verbose
      if prefix.present?
        if pname.start_with?( prefix )
          pname = name.slice( (prefix.length)..(name.length) )
        else
          lines << "#{name} does not start with #{prefix}" if verbose
          lines << "before pop prefix_stack=#{prefix_stack}" if verbose
          prefix_stack.pop
          lines << "after pop prefix_stack=#{prefix_stack}" if verbose
          prefix = prefix_stack.last
          while ( !prefix_stack.empty? && !pname.start_with?( prefix ) ) do
            lines << "before pop prefix_stack=#{prefix_stack}" if verbose
            prefix_stack.pop
            lines << "after pop prefix_stack=#{prefix_stack}" if verbose
            prefix = prefix_stack.last
          end
          if prefix.present? && pname.start_with?( prefix )
            pname = name.slice( (prefix.length)..(name.length) )
          end
        end
      end
      lines << "#{line_prefix * depth}#{pname}" unless verbose
      lines << "#{line_prefix * depth}#{pname} <-- #{name}" if verbose
      lines << "before prefix_stack=#{prefix_stack}" if name.end_with?( '/' ) && verbose
      prefix_stack.push( name ) if name.end_with? '/'
      lines << "after prefix_stack=#{prefix_stack}" if name.end_with?( '/' ) && verbose
    end
    return lines
  end

end