# frozen_string_literal: true

module MetadataHelper

  @@FIELD_SEP = '; '.freeze

  def self.file_from_file_set( file_set )
    file = nil
    files = file_set.files
    unless  files.nil? || files.size.zero?
      file = files[0]
      files.each do |f|
        file = f unless f.original_name.empty?
      end
    end
    return file
  end

  def self.human_readable_size( value )
    value = value.to_i
    return ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert( value, precision: 3 )
  end

  def self.log_lines( filename, *lines )
    File.open( filename, "a" ) do |f|
      lines.each { |line| f.puts line }
    end
  end

  def self.metadata_filename_collection( pathname_dir, collection )
    pathname_dir.join "w_#{collection.id}_metadata_report.txt"
  end

  def self.metadata_filename_collection_work( pathname_dir, collection, work )
    pathname_dir.join "c_#{collection.id}_w_#{work.id}_metadata_report.txt"
  end

  def self.metadata_filename_work( pathname_dir, work )
    pathname_dir.join "w_#{work.id}_metadata_report.txt"
  end

  def self.ordered( ordered_values: nil, values: nil )
    return nil if values.nil?
    if DeepBlueDocs::Application.config.do_ordered_list_hack
      unless ordered_values.nil?
        begin
          values = OrderedStringHelper.deserialize( ordered_values )
        rescue OrderedStringHelper::DeserializeError
          # fallback to original values, which are stored in an unspecified order
          return values
        end
      end
    end
    return values
  end

  def self.ordered_values( ordered_values: nil, values: nil )
    return nil if values.nil?
    rv = nil
    if DeepBlueDocs::Application.config.do_ordered_list_hack
      if DeepBlueDocs::Application.config.do_ordered_list_hack_save
        rv = OrderedStringHelper.serialize( values )
      elsif !ordered_values.nil?
        rv = OrderedStringHelper.serialize( values )
      end
    end
    return rv
  end

  def self.report_collection( collection, dir: nil, out: nil, depth: '==' )
    target_file = nil
    if out.nil?
      target_file = metadata_filename_collection( dir, collection )
      open( target_file, 'w' ) do |out2|
        report_collection( collection, out: out2, depth: depth )
      end
    else
      title = title( collection, field_sep: '' )
      out.puts "#{depth} Collection: #{title} #{depth}"
      report_item( out, "ID: ", collection.id )
      report_item( out, "Title: ", collection.title, one_line: true )
      report_item( out, "Total items: ", collection.member_objects.count )
      report_item( out, "Total size: ", human_readable_size( collection.bytes ) )
      report_item( out, "Creator: ", collection.creator, one_line: false, item_prefix: "\t" )
      report_item( out, "Keyword: ", collection.keyword, one_line: false, item_prefix: "\t" )
      report_item( out, "Discipline: ", collection.subject, one_line: false, item_prefix: "\t" )
      report_item( out, "Language: ", collection.language )
      report_item( out, "Citation to related material: ", collection.isReferencedBy )
      report_item( out, "Visibility: ", collection.visibility )
      if 0 < collection.member_objects.count
        collection.member_objects.each do |generic_work|
          out.puts
          report_generic_work( generic_work, out: out, depth: "=#{depth}" )
        end
      end
    end
    return target_file
  end

  def self.report_collection_work( collection, generic_work, dir: nil, out: nil, depth: '==' )
    target_file = nil
    if out.nil?
      target_file = metadata_filename_collection_work( dir, collection, generic_work )
      open( target_file, 'w' ) do |out2|
        report_collection_work( collection, generic_work, out: out2, depth: depth )
      end
    else
      report_work( generic_work, out: out, depth: depth )
    end
    return target_file
  end

  def self.report_file_set( file_set, out: nil, depth: '==' )
    out.puts "#{depth} File Set: #{file_set.label} #{depth}"
    report_item( out, "ID: ", file_set.id )
    report_item( out, "File name: ", file_set.label )
    report_item( out, "Date uploaded: ", file_set.date_uploaded )
    report_item( out, "Date modified: ", file_set.date_uploaded )
    report_item( out, "Total file size: ", human_readable_size( file_set.file_size[0] ) )
    report_item( out, "Checksum: ", file_set.original_checksum )
    report_item( out, "Mimetype: ", file_set.mime_type )
  end

  def self.report_generic_work( generic_work, dir: nil, out: nil, depth: '==' )
    target_file = nil
    if out.nil?
      target_file = metadata_filename_work( dir, generic_work )
      open( target_file, 'w' ) do |out2|
        report_generic_work( generic_work, out: out2, depth: depth )
      end
    else
      title = title( generic_work, field_sep: '' )
      out.puts "#{depth} Generic Work: #{title} #{depth}"
      report_item( out, "ID: ", generic_work.id )
      report_item( out, "Title: ", generic_work.title, one_line: true )
      report_item( out, "Methodology: ", generic_work.methodology )
      report_item( out, "Description: ", generic_work.description, one_line: false, item_prefix: "\t" )
      report_item( out, "Creator: ", generic_work.creator, one_line: false, item_prefix: "\t" )
      report_item( out, "Depositor: ", generic_work.depositor )
      report_item( out, "Contact: ", generic_work.authoremail )
      report_item( out, "Discipline: ", generic_work.subject, one_line: false, item_prefix: "\t" )
      report_item( out, "Funded by: ", generic_work.fundedby )
      report_item( out, "ORSP Grant Number: ", generic_work.grantnumber )
      report_item( out, "Keyword: ", generic_work.keyword, one_line: false, item_prefix: "\t" )
      report_item( out, "Date coverage: ", generic_work.date_coverage )
      report_item( out, "Citation to related material: ", generic_work.isReferencedBy )
      report_item( out, "Language: ", generic_work.language )
      report_item( out, "Total file count: ", generic_work.file_set_ids.count )
      report_item( out, "Total file size: ", human_readable_size( generic_work.total_file_size ) )
      report_item( out, "DOI: ", generic_work.doi, optional: true )
      report_item( out, "Visibility: ", generic_work.visibility )
      report_item( out, "Rights: ", generic_work.rights )
      report_item( out, "Admin set id: ", generic_work.admin_set_id )
      report_item( out, "Tombstone: ", generic_work.tombstone, optional: true )
      if 0 < generic_work.file_sets.count
        generic_work.file_sets.each do |file_set|
          out.puts
          report_file_set( file_set, out: out, depth: "=#{depth}" )
        end
      end
    end
    return target_file
  end

  def self.report_item( out,
                        label,
                        value,
                        item_prefix: '',
                        item_postfix: '',
                        item_seperator: @@FIELD_SEP,
                        one_line: nil,
                        optional: false )
    multi_item = value.respond_to?( :count ) && value.respond_to?( :each )
    if optional
      return if value.nil?
      return if value.to_s.empty?
      return if multi_item && value.count.zero?
    end
    if one_line.nil?
      one_line = true
      if multi_item
        one_line = false if 1 < value.count
      end
    end
    if one_line
      if value.respond_to?( :join )
        out.puts( "#{label}#{item_prefix}#{value.join( "#{item_prefix}#{item_seperator}#{item_postfix}" )}#{item_postfix}" )
      elsif multi_item
        out.print( label.to_s )
        count = 0
        value.each do |item|
          count += 1
          out.print( "#{item_prefix}#{item}#{item_postfix}" )
          out.print( item_seperator.to_s ) unless value.count == count
        end
        out.puts
      else
        out.puts( "#{label}#{item_prefix}#{value}#{item_postfix}" )
      end
    else
      out.puts( label.to_s )
      if multi_item
        value.each { |item| out.puts( "#{item_prefix}#{item}#{item_postfix}" ) }
      else
        out.puts( "#{item_prefix}#{value}#{item_postfix}" )
      end
    end
  end

  def self.title( curration_concern, field_sep: @@FIELD_SEP )
    curration_concern.title.join( field_sep )
  end

  def self.yaml_escape_value( value, comment: false, escape: false )
    return "" if value.nil?
    return value unless escape
    return value if comment
    value = value.to_json
    return "" if "\"\"" == value
    return value
  end

  def self.yaml_file_set( file_set, out: nil, depth: '==' )
    out.puts "#{depth} File Set: #{file_set.label} #{depth}"
    yaml_item( out, "ID: ", file_set.id )
    yaml_item( out, "File name: ", file_set.label )
    yaml_item( out, "Date uploaded: ", file_set.date_uploaded )
    yaml_item( out, "Date modified: ", file_set.date_uploaded )
    yaml_item( out, "Total file size: ", human_readable_size( file_set.file_size[0] ) )
    yaml_item( out, "Checksum: ", file_set.original_checksum )
    yaml_item( out, "Mimetype: ", file_set.mime_type )
  end

  def self.yaml_filename_work( pathname_dir, work, task: 'populate' )
    pathname_dir = Pathname.new pathname_dir unless pathname_dir.is_a? Pathname
    pathname_dir.join "w_#{work.id}_#{task}.yml"
  end

  def self.yaml_generic_work_export_files( generic_work, target_dirname: nil, log_filename: nil, overwrite: true )
    log_file = target_dirname.join ".export.log" if log_filename.nil?
    open( log_file, 'w' ) { |f| f.write('') } # erase log file
    start_time = Time.now
    log_lines( log_file,
               "Starting yaml generic work export of files at #{start_time} ...",
               "Generic work id: #{generic_work.id}",
               "Total file count: #{generic_work.file_sets.count}")
    total_byte_count = 0
    if 0 < generic_work.file_sets.count
      generic_work.file_sets.each do |file_set|
        file = file_from_file_set( file_set )
        export_file_name = file.original_name
        export_file_name = target_dirname.join "#{file_set.id}_#{export_file_name}"
        write_file = if overwrite
                       true
                     else
                       !File.exist?( export_file_name )
                     end
        if write_file
          source_uri = file.uri.value
          log_lines( log_file, "Starting file export of #{export_file_name} (#{file.size} bytes) at #{Time.now}" )
          bytes_copied = open( source_uri ) { |io| IO.copy_stream( io, export_file_name ) }
          total_byte_count += bytes_copied
          log_lines( log_file, "Finisehd file export of #{export_file_name} (#{file.size} bytes) at #{Time.now}" )
        else
          log_lines( log_file, "Skipping file export of #{export_file_name} (#{file.size} bytes)." )
        end
      end
    end
    end_time = Time.now
    log_lines( log_file,
               "Total bytes exported: #{total_byte_count}",
               "... finished yaml generic work export of files at #{end_time}.")
  rescue Exception => e # rubocop:disable Lint/RescueException
    # rubocop:disable Rails/Output
    puts "#{e.class}: #{e.message} at #{e.backtrace.join("\n")}"
    # rubocop:enable Rails/Output
  end

  def self.yaml_generic_work_populate( generic_work,
                                       dir: "/deepbluedata-prep/",
                                       out: nil,
                                       export_files: true,
                                       overwrite_export_files: true,
                                       source: "DBDv1",
                                       target_filename: nil,
                                       target_dirname: nil )
    target_file = nil
    dir = Pathname.new dir unless dir.is_a? Pathname
    if out.nil?
      generic_work = GenericWork.find generic_work if generic_work.is_a? String
      target_file = yaml_filename_work( dir, generic_work )
      target_dir = yaml_targetdir_work( dir, generic_work )
      Dir.mkdir( target_dir ) unless Dir.exist? target_dir
      open( target_file, 'w' ) do |out2|
        yaml_generic_work_populate( generic_work,
                                    out: out2,
                                    export_files: export_files,
                                    overwrite_export_files: overwrite_export_files,
                                    source: source,
                                    target_filename: target_file,
                                    target_dirname: target_dir )
      end
      if export_files
        yaml_generic_work_export_files( generic_work, target_dirname: target_dir, overwrite: overwrite_export_files )
      end
    else
      indent_base = " " * 2
      indent = indent_base * 0
      yaml_line( out, indent, target_filename.to_s, comment: true )
      yaml_line( out, indent, "bundle exec rake umrdr:populate[#{target_filename}]", comment: true )
      yaml_line( out, indent, "---" )
      yaml_line( out, indent, ':user:' )
      indent = indent_base * 1
      yaml_line( out, indent, ':email:', generic_work.depositor )
      yaml_line( out, indent, ':visibility:', generic_work.visibility )
      yaml_line( out, indent, ':source:', source )
      yaml_line( out, indent, ':works:' )
      indent = indent_base * 2
      yaml_item( out, indent, ":admin_set_id:", generic_work.admin_set_id, comment: true )
      yaml_item( out, indent, ":authoremail:", generic_work.authoremail )
      yaml_item( out, indent, ":creator:", generic_work.creator, escape: true )
      yaml_item( out, indent, ":date_uploaded:", generic_work.date_uploaded )
      yaml_item( out, indent, ":date_modified:", generic_work.date_modified )
      yaml_item( out, indent, ":date_coverage:", generic_work.date_coverage[0] )
      yaml_item( out, indent, ":description:", generic_work.description, escape: true )
      yaml_item( out, indent, ":depositor:", generic_work.depositor )
      yaml_item( out, indent, ":subject:", generic_work.subject[0] )
      yaml_item( out, indent, ":doi:", generic_work.doi, escape: true )
      yaml_item( out, indent, ":fundedby:", generic_work.fundedby[0] )
      yaml_item( out, indent, ":grantnumber:", generic_work.grantnumber, escape: true )
      yaml_item( out, indent, ":isReferencedBy:", generic_work.isReferencedBy, escape: true )
      yaml_item( out, indent, ':keyword:', generic_work.keyword, escape: true )
      yaml_item( out, indent, ":language:", generic_work.language, escape: true )
      yaml_item( out, indent, ":methodology:", generic_work.methodology, escape: true )
      yaml_item( out, indent, ":rights: ", generic_work.rights[0], escape: true )
      yaml_item( out, indent, ':title:', generic_work.title, escape: true )
      yaml_item( out, indent, ":tombstone:", generic_work.tombstone[0] )
      yaml_item( out, indent, ":total_file_count:", generic_work.file_set_ids.count, comment: true )
      yaml_item( out, indent, ":total_file_size:", generic_work.total_file_size )
      yaml_item( out, indent, ":total_file_size_human_readable:", human_readable_size( generic_work.total_file_size ), comment: true )
      yaml_item( out, indent, ":visibility: ", generic_work.visibility, comment: true )

      yaml_line( out, indent_base * 2, ':filenames:' )
      if 0 < generic_work.file_sets.count
        indent = indent_base * 3 + "- "
        generic_work.file_sets.each do |file_set|
          yaml_item( out, indent, '', file_set.label, escape: true )
        end
      end
      yaml_line( out, indent_base * 2, ':files:' )
      if 0 < generic_work.file_sets.count
        indent = indent_base * 3 + "- "
        generic_work.file_sets.each do |file_set|
          # puts "fsid=#{fsid}"
          # file_set = FileSet.find fsid
          # puts "file_set.files=#{file_set.files}"
          # STDOUT.flush
          # #byebug
          file = file_from_file_set( file_set )
          file_name = file.original_name
          file_path = target_dirname.join "#{file_set.id}_#{file_name}"
          yaml_item( out, indent, '', file_path.to_s, escape: true )
        end
      end
    end
    return target_file
  end

  def self.yaml_item( out, indent, label, value = '', comment: false, indent_base: "  ", label_postfix: ' ', escape: false )
    indent = "# #{indent}" if comment
    if value.respond_to?(:each)
      out.puts "#{indent}#{label}#{label_postfix}"
      indent += indent_base
      value.each { |item| out.puts "#{indent}- #{yaml_escape_value( item, comment: comment, escape: escape )}" }
    else
      out.puts "#{indent}#{label}#{label_postfix}#{yaml_escape_value( value, comment: comment, escape: escape )}"
    end
  end

  def self.yaml_line( out, indent, label, value = '', comment: false, label_postfix: ' ', escape: false )
    indent = "# #{indent}" if comment
    out.puts "#{indent}#{label}#{label_postfix}#{yaml_escape_value( value, comment: comment, escape: escape )}"
  end

  def self.yaml_targetdir_work( pathname_dir, work, task: 'populate' )
    pathname_dir = Pathname.new pathname_dir unless pathname_dir.is_a? Pathname
    pathname_dir.join "w_#{work.id}_#{task}"
  end

end
