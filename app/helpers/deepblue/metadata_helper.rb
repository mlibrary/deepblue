# frozen_string_literal: true

module Deepblue

  module MetadataHelper

    SOURCE_DBDv1 = 'DBDv1' # rubocop:disable Style/ConstantName
    SOURCE_DBDv2 = 'DBDv2' # rubocop:disable Style/ConstantName
    DEFAULT_BASE_DIR = "/deepbluedata-prep/"
    DEFAULT_SOURCE = SOURCE_DBDv2
    DEFAULT_TASK = 'populate'
    FIELD_SEP = '; '
    HEADER_TYPE_COLLECTIONS = ':collections:'
    HEADER_TYPE_WORKS = ':works:'
    MODE_APPEND = 'append'
    MODE_BUILD = 'build'
    PREFIX_COLLECTION = 'c_'
    PREFIX_WORK = 'w_'

    def self.file_from_file_set( file_set )
      file = nil
      files = file_set.files
      unless files.nil? || files.size.zero?
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

    def self.metadata_multi_valued?( attribute_value )
      return false if attribute_value.blank?
      return true if attribute_value.respond_to?( :each ) && 1 < attribute_value.size
      false
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
        title = report_title( collection, field_sep: '' )
        out.puts "#{depth} Collection: #{title} #{depth}"
        report_item( out, "ID: ", collection.id )
        report_item( out, "Title: ", collection.title, one_line: true )
        report_item( out, "Total items: ", collection.member_objects.count )
        report_item( out, "Total size: ", human_readable_size( collection.bytes ) )
        report_item( out, "Creator: ", collection.creator, one_line: false, item_prefix: "\t" )
        report_item( out, "Keyword: ", collection.keyword, one_line: false, item_prefix: "\t" )
        report_item( out, "Discipline: ", collection.subject_discipline, one_line: false, item_prefix: "\t" )
        report_item( out, "Language: ", collection.language )
        report_item( out, "Citation to related material: ", collection.referenced_by )
        report_item( out, "Visibility: ", collection.visibility )
        if collection.member_objects.count.positive?
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
      report_item( out, "Date modified: ", file_set.date_modified )
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
        title = report_title( generic_work, field_sep: '' )
        out.puts "#{depth} Generic Work: #{title} #{depth}"
        report_item( out, "ID: ", generic_work.id )
        report_item( out, "Title: ", generic_work.title, one_line: true )
        report_item( out, "Prior Identifier: ", generic_work.prior_identifier, one_line: true )
        report_item( out, "Methodology: ", generic_work.methodology )
        report_item( out, "Description: ", generic_work.description, one_line: false, item_prefix: "\t" )
        report_item( out, "Creator: ", generic_work.creator, one_line: false, item_prefix: "\t" )
        report_item( out, "Depositor: ", generic_work.depositor )
        report_item( out, "Contact: ", generic_work.authoremail )
        report_item( out, "Discipline: ", generic_work.subject_discipline, one_line: false, item_prefix: "\t" )
        report_item( out, "Funded by: ", generic_work.fundedby )
        report_item( out, "ORSP Grant Number: ", generic_work.grantnumber )
        report_item( out, "Keyword: ", generic_work.keyword, one_line: false, item_prefix: "\t" )
        report_item( out, "Date coverage: ", generic_work.date_coverage )
        report_item( out, "Citation to related material: ", generic_work.referenced_by )
        report_item( out, "Language: ", generic_work.language )
        report_item( out, "Total file count: ", generic_work.file_set_ids.count )
        report_item( out, "Total file size: ", human_readable_size( generic_work.total_file_size ) )
        report_item( out, "DOI: ", generic_work.doi, optional: true )
        report_item( out, "Visibility: ", generic_work.visibility )
        report_item( out, "Rights: ", generic_work.rights_license )
        report_item( out, "Admin set id: ", generic_work.admin_set_id )
        report_item( out, "Tombstone: ", generic_work.tombstone, optional: true )
        if generic_work.file_sets.count.positive?
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
                          item_seperator: FIELD_SEP,
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

    def self.report_title( curation_concern, field_sep: FIELD_SEP )
      curation_concern.title.join( field_sep )
    end

    def self.yaml_body_collections( out, indent:, curation_concern:, source: )
      yaml_item( out, indent, ":id:", curation_concern.id )
      yaml_item( out, indent, ":collection_type:", curation_concern.collection_type.machine_id, escape: true )
      yaml_item( out, indent, ":collection_type_gid:", curation_concern.collection_type_gid, escape: true )
      yaml_item( out, indent, ":creator:", curation_concern.creator, escape: true )
      yaml_item( out, indent, ":date_created:", curation_concern.date_created )
      yaml_item( out, indent, ":date_modified:", curation_concern.date_modified )
      yaml_item( out, indent, ":description:", curation_concern.description, escape: true )
      yaml_item( out, indent, ":depositor:", curation_concern.depositor )
      yaml_item( out, indent, ":doi:", curation_concern.doi, escape: true )
      yaml_item_referenced_by( out, indent, curation_concern: curation_concern, source: source )
      yaml_item( out, indent, ':keyword:', curation_concern.keyword, escape: true )
      yaml_item( out, indent, ":language:", curation_concern.language, escape: true )
      yaml_item_prior_identifier( out, indent, curation_concern: curation_concern, source: source )
      yaml_item_subject( out, indent, curation_concern: curation_concern, source: source )
      yaml_item( out, indent, ':title:', curation_concern.title, escape: true )
      yaml_item( out, indent, ":tombstone:", curation_concern.tombstone, single_value: true )
      yaml_item( out, indent, ":total_work_count:", curation_concern.work_ids.count )
      yaml_item( out, indent, ":total_file_size:", curation_concern.total_file_size )
      yaml_item( out,
                 indent,
                 ":total_file_size_human_readable:",
                 human_readable_size( curation_concern.total_file_size ),
                 escape: true )
      yaml_item( out, indent, ":visibility:", curation_concern.visibility )
    end

    def self.yaml_body_files( out, indent_base:, indent:, curation_concern:, source:, target_dirname: )
      indent_first_line = indent
      yaml_line( out, indent_first_line, ':file_set_ids:' )
      return unless curation_concern.file_sets.count.positive?
      indent = indent_base + indent_first_line + "-"
      curation_concern.file_sets.each do |file_set|
        yaml_item( out, indent, '', file_set.id, escape: true )
      end
      curation_concern.file_sets.each do |file_set|
        file_id = ":f_#{file_set.id}:"
        yaml_line( out, indent_first_line, file_id )
        indent = indent_base + indent_first_line
        yaml_item( out, indent, ':id:', file_set.id, escape: true )
        single_value = 1 == file_set.title.size
        yaml_item( out, indent, ':title:', file_set.title, escape: true, single_value: single_value )
        # file_ids = file_set.prior_identifier
        # file_ids = [] if file_ids.nil?
        # file_ids << file_set.id
        # yaml_item( out, indent, ':prior_identifier:', ActiveSupport::JSON.encode( file_ids ) )
        yaml_item_prior_identifier( out, indent, curation_concern: curation_concern, source: source )
        file_path = yaml_export_file_path( target_dirname: target_dirname, file_set: file_set )
        yaml_item( out, indent, ':file_path:', file_path.to_s, escape: true )
        yaml_item( out, indent, ":date_created:", file_set.date_created )
        yaml_item( out, indent, ":date_uploaded:", file_set.date_uploaded )
        yaml_item( out, indent, ":date_modified:", file_set.date_modified )
        file_size = if file_set.file_size.blank?
                      file_set.original_file.nil? ? 0 : file_set.original_file.size
                    else
                      file_set.file_size[0]
                    end
        yaml_item( out, indent, ":file_size:", file_size )
        yaml_item( out, indent, ":file_size_human_readable:", human_readable_size( file_size ), escape: true )
        yaml_item( out, indent, ":label:", file_set.label, escape: true )
        yaml_item( out, indent, ":mime_type:", file_set.mime_type, escape: true )
        value = file_set.original_checksum.blank? ? '' : file_set.original_checksum[0]
        yaml_item( out, indent, ":original_checksum:", value )
        value = file_set.original_file.nil? ? nil : file_set.original_file.original_name
        yaml_item( out, indent, ":original_name:", value, escape: true )
        yaml_item( out, indent, ":visibility:", file_set.visibility )
      end
    end

    def self.yaml_body_works( out, indent:, curation_concern:, source: )
      yaml_item( out, indent, ":id:", curation_concern.id )
      yaml_item( out, indent, ":admin_set_id:", curation_concern.admin_set_id, escape: true )
      yaml_item( out, indent, ":authoremail:", curation_concern.authoremail )
      yaml_item( out, indent, ":creator:", curation_concern.creator, escape: true )
      yaml_item( out, indent, ":date_created:", curation_concern.date_created )
      yaml_item( out, indent, ":date_uploaded:", curation_concern.date_uploaded )
      yaml_item( out, indent, ":date_modified:", curation_concern.date_modified )
      yaml_item( out, indent, ":date_coverage:", curation_concern.date_coverage, single_value: true )
      yaml_item( out, indent, ":description:", curation_concern.description, escape: true )
      yaml_item( out, indent, ":depositor:", curation_concern.depositor )
      yaml_item( out, indent, ":doi:", curation_concern.doi, escape: true )
      yaml_item( out, indent, ":fundedby:", curation_concern.fundedby, single_value: true, escape: true )
      yaml_item( out, indent, ":grantnumber:", curation_concern.grantnumber, escape: true )
      yaml_item_referenced_by( out, indent, curation_concern: curation_concern, source: source )
      yaml_item( out, indent, ':keyword:', curation_concern.keyword, escape: true )
      yaml_item( out, indent, ":language:", curation_concern.language, escape: true )
      yaml_item( out, indent, ":methodology:", curation_concern.methodology, escape: true )
      yaml_item_prior_identifier( out, indent, curation_concern: curation_concern, source: source )
      yaml_item( out, indent, ":rights_license: ", curation_concern.rights_license, escape: true )
      yaml_item_subject( out, indent, curation_concern: curation_concern, source: source )
      yaml_item( out, indent, ':title:', curation_concern.title, escape: true )
      yaml_item( out, indent, ":tombstone:", curation_concern.tombstone, single_value: true )
      yaml_item( out, indent, ":total_file_count:", curation_concern.file_set_ids.count )
      yaml_item( out, indent, ":total_file_size:", curation_concern.total_file_size )
      yaml_item( out,
                 indent,
                 ":total_file_size_human_readable:",
                 human_readable_size( curation_concern.total_file_size ),
                 escape: true )
      yaml_item( out, indent, ":visibility:", curation_concern.visibility )
    end

    def self.yaml_escape_value( value, comment: false, escape: false )
      return "" if value.nil?
      return value unless escape
      return value if comment
      value = value.to_json
      return "" if "\"\"" == value
      return value
    end

    def self.yaml_export_file_path( target_dirname:, file_set: )
      file = file_from_file_set( file_set )
      export_file_name = file.original_name
      target_dirname.join "#{file_set.id}_#{export_file_name}"
    end

    def self.yaml_filename( pathname_dir:, id:, prefix:, task: )
      pathname_dir = Pathname.new pathname_dir unless pathname_dir.is_a? Pathname
      pathname_dir.join "#{prefix}#{id}_#{task}.yml"
    end

    def self.yaml_filename_collection( pathname_dir:, collection:, task: DEFAULT_TASK )
      yaml_filename( pathname_dir: pathname_dir, id: collection.id, prefix: PREFIX_COLLECTION, task: task )
    end

    def self.yaml_filename_work( pathname_dir:, work:, task: DEFAULT_TASK )
      yaml_filename( pathname_dir: pathname_dir, id: work.id, prefix: PREFIX_WORK, task: task )
    end

    def self.yaml_header( out, indent:, curation_concern:, header_type:, source:, mode: )
      yaml_line( out, indent, ':email:', curation_concern.depositor )
      yaml_line( out, indent, ':visibility:', curation_concern.visibility )
      yaml_line( out, indent, ':ingester:', '' )
      yaml_line( out, indent, ':source:', source )
      yaml_line( out, indent, ':export_timestamp:', DateTime.now.to_s )
      yaml_line( out, indent, ':mode:', mode )
      yaml_line( out, indent, ':id:', curation_concern.id )
      yaml_line( out, indent, header_type )
    end

    def self.yaml_header_populate( out, indent:, target_filename: )
      yaml_line( out, indent, target_filename.to_s, comment: true )
      yaml_line( out, indent, "bundle exec rake umrdr:populate[#{target_filename}]", comment: true )
      yaml_line( out, indent, "---" )
      yaml_line( out, indent, ':user:' )
    end

    def self.yaml_item( out,
                        indent,
                        label,
                        value = '',
                        single_value: false,
                        comment: false,
                        indent_base: "  ",
                        label_postfix: ' ',
                        escape: false )

      indent = "# #{indent}" if comment
      if single_value && value.present? && value.respond_to?( :each )
        value = value[0]
        out.puts "#{indent}#{label}#{label_postfix}#{yaml_escape_value( value, comment: comment, escape: escape )}"
      elsif value.respond_to?(:each)
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

    def self.yaml_item_prior_identifier( out, indent, curation_concern:, source: )
      if source == SOURCE_DBDv1
        yaml_item( out, indent, ":prior_identifier:", '' )
      else
        # ids = curation_concern.prior_identifier
        # ids = [] if ids.nil?
        # ids << curation_concern.id
        # yaml_item( out, indent, ':prior_identifier:', ActiveSupport::JSON.encode( ids ) )
        yaml_item( out, indent, ":prior_identifier:", curation_concern.prior_identifier )
      end
    end

    def self.yaml_item_referenced_by( out, indent, curation_concern:, source: )
      if source == SOURCE_DBDv1
        yaml_item( out, indent, ":isReferencedBy:", curation_concern.isReferencedBy, escape: true )
      else
        yaml_item( out, indent, ":referenced_by:", curation_concern.referenced_by, escape: true )
      end
    end

    def self.yaml_item_subject( out, indent, curation_concern:, source: )
      if source == SOURCE_DBDv1
        yaml_item( out, indent, ":subject:", curation_concern.subject, escape: true )
      else
        yaml_item( out, indent, ":subject_discipline:", curation_concern.subject_discipline, escape: true )
      end
    end

    def self.yaml_populate_collection( collection:,
                                       dir: DEFAULT_BASE_DIR,
                                       out: nil,
                                       populate_works: true,
                                       export_files: true,
                                       overwrite_export_files: true,
                                       source: DEFAULT_SOURCE,
                                       mode: MODE_BUILD,
                                       target_filename: nil,
                                       target_dirname: nil )

      target_file = nil
      dir = Pathname.new dir unless dir.is_a? Pathname
      if out.nil?
        collection = Collection.find collection if collection.is_a? String
        target_file = yaml_filename_collection( pathname_dir: dir, collection: collection )
        target_dir = yaml_targetdir_collection( pathname_dir: dir, collection: collection )
        Dir.mkdir( target_dir ) unless Dir.exist? target_dir
        open( target_file, 'w' ) do |out2|
          yaml_populate_collection( collection: collection,
                                    out: out2,
                                    populate_works: populate_works,
                                    export_files: false,
                                    overwrite_export_files: overwrite_export_files,
                                    source: source,
                                    mode: mode,
                                    target_filename: target_file,
                                    target_dirname: target_dir )
        end
        if export_files
          collection.member_objects.each do |work|
            next unless work.is_a? DataSet
            yaml_work_export_files( work: work, target_dirname: target_dir, overwrite: overwrite_export_files )
          end
        end
      else
        indent_base = " " * 2
        indent = indent_base * 0
        yaml_header_populate( out, indent: indent, target_filename: target_filename )
        indent = indent_base * 1
        yaml_header( out,
                     indent: indent,
                     curation_concern: collection,
                     header_type: HEADER_TYPE_COLLECTIONS,
                     source: source,
                     mode: mode )
        indent = indent_base * 2
        yaml_body_collections( out, indent: indent, curation_concern: collection )
        return unless populate_works
        return unless collection.member_objects.size.positive?
        indent = indent_base * 2
        yaml_line( out, indent, HEADER_TYPE_WORKS )
        indent = indent_base + indent + "-"
        collection.member_objects.each do |work|
          next unless work.is_a? DataSet
          yaml_item( out, indent, '', work.id, escape: true )
        end
        indent = indent_base * 2
        collection.member_objects.each do |work|
          next unless work.is_a? DataSet
          indent = indent_base * 2
          yaml_line( out, indent, ":works_#{work.id}:" )
          indent = indent_base * 3
          yaml_body_works( out, indent: indent, curation_concern: work, source: source )
          yaml_body_files( out,
                           indent_base: indent_base,
                           indent: indent,
                           curation_concern: work,
                           source: source,
                           target_dirname: target_dirname )
        end
      end
    end

    def self.yaml_populate_work( curation_concern:,
                                 dir: DEFAULT_BASE_DIR,
                                 out: nil,
                                 export_files: true,
                                 overwrite_export_files: true,
                                 source: DEFAULT_SOURCE,
                                 mode: MODE_BUILD,
                                 target_filename: nil,
                                 target_dirname: nil )

      target_file = nil
      dir = Pathname.new dir unless dir.is_a? Pathname
      if out.nil?
        curation_concern = DataSet.find curation_concern if curation_concern.is_a? String
        target_file = yaml_filename_work( pathname_dir: dir, work: curation_concern )
        target_dir = yaml_targetdir_work( pathname_dir: dir, work: curation_concern )
        Dir.mkdir( target_dir ) unless Dir.exist? target_dir
        open( target_file, 'w' ) do |out2|
          yaml_populate_work( curation_concern: curation_concern,
                              out: out2,
                              export_files: export_files,
                              overwrite_export_files: overwrite_export_files,
                              source: source,
                              mode: mode,
                              target_filename: target_file,
                              target_dirname: target_dir )
        end
        if export_files
          yaml_work_export_files( work: curation_concern, target_dirname: target_dir, overwrite: overwrite_export_files )
        end
      else
        indent_base = " " * 2
        indent = indent_base * 0
        yaml_header_populate( out, indent: indent, target_filename: target_filename )
        indent = indent_base * 1
        yaml_header( out,
                     indent: indent,
                     curation_concern: curation_concern,
                     header_type: HEADER_TYPE_WORKS,
                     source: source,
                     mode: mode )
        indent = indent_base * 2
        yaml_body_works( out, indent: indent, curation_concern: curation_concern )
        yaml_body_files( out,
                         indent_base: indent_base,
                         indent: indent,
                         curation_concern: curation_concern,
                         source: source,
                         target_dirname: target_dirname )
      end
      return target_file
    end

    def self.yaml_targetdir( pathname_dir:, id:, prefix:, task: )
      pathname_dir = Pathname.new pathname_dir unless pathname_dir.is_a? Pathname
      pathname_dir.join "#{prefix}#{id}_#{task}"
    end

    def self.yaml_targetdir_collection( pathname_dir:, collection:, task: DEFAULT_TASK )
      yaml_targetdir( pathname_dir: pathname_dir, id: collection.id, prefix: PREFIX_COLLECTION, task: task )
    end

    def self.yaml_targetdir_work( pathname_dir:, work:, task: DEFAULT_TASK )
      yaml_targetdir( pathname_dir: pathname_dir, id: work.id, prefix: PREFIX_WORK, task: task )
    end

    def self.yaml_work_export_files( work:, target_dirname: nil, log_filename: nil, overwrite: true )
      log_file = target_dirname.join ".export.log" if log_filename.nil?
      open( log_file, 'w' ) { |f| f.write('') } # erase log file
      start_time = Time.now
      log_lines( log_file,
                 "Starting yaml generic work export of files at #{start_time} ...",
                 "Generic work id: #{work.id}",
                 "Total file count: #{work.file_sets.count}")
      total_byte_count = 0
      if work.file_sets.count.positive?
        work.file_sets.each do |file_set|
          export_file_name = yaml_export_file_path( target_dirname: target_dirname, file_set: file_set )
          write_file = if overwrite
                         true
                       else
                         !File.exist?( export_file_name )
                       end
          if write_file
            file = file_from_file_set( file_set )
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

  end

end
