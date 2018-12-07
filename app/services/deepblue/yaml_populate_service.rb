# frozen_string_literal: true

module Deepblue

  class YamlPopulateService

    DEFAULT_CREATE_ZERO_LENGTH_FILES = true
    DEFAULT_OVERWRITE_EXPORT_FILES = true

    attr_accessor :mode, :source

    # TODO: count these
    attr_reader :total_collections_exported, :total_file_sets_exported, :total_works_exported, :total_users_exported

    attr_accessor :overwrite_export_files, :create_zero_length_files

    def initialize( create_zero_length_files: DEFAULT_CREATE_ZERO_LENGTH_FILES,
                    mode: MetadataHelper::MODE_BUILD,
                    overwrite_export_files: DEFAULT_OVERWRITE_EXPORT_FILES,
                    source: MetadataHelper::DEFAULT_SOURCE )

      @create_zero_length_files = create_zero_length_files
      @mode = mode
      @overwrite_export_files = overwrite_export_files
      @source = source
      @total_collections_exported = 0
      @total_file_sets_exported = 0
      @total_file_sets_size_exported = 0
      @total_works_exported = 0
      @total_users_exported = 0
    end

    def yaml_body_collections( out, indent:, curation_concern: )
      @total_collections_exported += 1
      yaml_item( out, indent, ":id:", curation_concern.id )
      if source == MetadataHelper::SOURCE_DBDv2
        yaml_item( out, indent, ":collection_type:", curation_concern.collection_type.machine_id, escape: true )
      end
      yaml_item( out, indent, ":edit_users:", curation_concern.edit_users, escape: true )
      yaml_item_prior_identifier( out, indent, curation_concern: curation_concern )
      yaml_item_subject( out, indent, curation_concern: curation_concern )
      yaml_item( out, indent, ":total_work_count:", curation_concern.work_ids.count )
      yaml_item( out, indent, ":total_file_size:", curation_concern.total_file_size )
      yaml_item( out,
                 indent,
                 ":total_file_size_human_readable:",
                 human_readable_size( curation_concern.total_file_size ),
                 escape: true )
      yaml_item( out, indent, ":visibility:", curation_concern.visibility )
      skip = %w[ prior_identifier rights rights_license subject subject_discipline total_file_size ]
      attribute_names_collection.each do |name|
        next if skip.include? name
        yaml_item_collection( out, indent, curation_concern, name: name )
      end
    end

    def yaml_body_files( out, indent_base:, indent:, curation_concern:, target_dirname: )
      indent_first_line = indent
      yaml_line( out, indent_first_line, ':file_set_ids:' )
      return unless curation_concern.file_sets.count.positive?
      indent = indent_base + indent_first_line + "-"
      curation_concern.file_sets.each do |file_set|
        yaml_item( out, indent, '', file_set.id, escape: true )
      end
      curation_concern.file_sets.each do |file_set|
        @total_file_sets_exported += 1
        log_provenance_migrate( curation_concern: file_set, parent: curation_concern ) if MetadataHelper::MODE_MIGRATE == mode
        file_id = ":#{yaml_file_set_id( file_set )}:"
        yaml_line( out, indent_first_line, file_id )
        indent = indent_base + indent_first_line
        yaml_item( out, indent, ':id:', file_set.id, escape: true )
        single_value = 1 == file_set.title.size
        yaml_item( out, indent, ':title:', file_set.title, escape: true, single_value: single_value )
        yaml_item_prior_identifier( out, indent, curation_concern: file_set )
        file_path = yaml_export_file_path( target_dirname: target_dirname, file_set: file_set )
        yaml_item( out, indent, ':file_path:', file_path.to_s, escape: true )
        checksum = yaml_file_set_checksum( file_set: file_set )
        yaml_item( out, indent, ":checksum_algorithm:", checksum.present? ? checksum.algorithm : '', escape: true )
        yaml_item( out, indent, ":checksum_value:", checksum.present? ? checksum.value : '', escape: true )
        yaml_item( out, indent, ":edit_users:", file_set.edit_users, escape: true )
        file_size = if file_set.file_size.blank?
                      file_set.original_file.nil? ? 0 : file_set.original_file.size
                    else
                      file_set.file_size[0]
                    end
        # puts "\nfile_size=#{file_size} file_size.class=#{file_size.class.name}\n" unless file_size.is_a? Integer
        @total_file_sets_size_exported += file_size.to_i
        yaml_item( out, indent, ":file_size:", file_size )
        yaml_item( out, indent, ":file_size_human_readable:", human_readable_size( file_size ), escape: true )
        yaml_item( out, indent, ":mime_type:", file_set.mime_type, escape: true )
        value = file_set.original_checksum.blank? ? '' : file_set.original_checksum[0]
        yaml_item( out, indent, ":original_checksum:", value )
        value = file_set.original_file.nil? ? nil : file_set.original_file.original_name
        yaml_item( out, indent, ":original_name:", value, escape: true )
        yaml_item( out, indent, ":visibility:", file_set.visibility )
        skip = %w[ title file_size ]
        attribute_names_file_set.each do |name|
          next if skip.include? name
          yaml_item_file_set( out, indent, file_set, name: name )
        end
      end
    end

    def yaml_body_user_body( out, indent_base:, indent:, user: )
      @total_users_exported += 1
      indent_first_line = indent
      user_email = ":#{yaml_user_email( user )}:"
      yaml_line( out, indent_first_line, user_email )
      indent = indent_base + indent_first_line
      yaml_item(out, indent, ':email:', user.email, escape: true )
      skip = %w[ email ]
      attribute_names_user.each do |name|
        next if skip.include? name
        yaml_item_user(out, indent, user, name: name )
      end
    end

    def yaml_body_users( out, indent_base:, indent:, users: )
      yaml_item( out, indent, ":total_user_count:", users.count )
      indent_first_line = indent
      yaml_line( out, indent_first_line, ':user_emails:' )
      return unless users.count.positive?
      indent = indent_base + indent_first_line + "-"
      users.each do |user|
        yaml_item( out, indent, '', user.email, escape: true )
      end
    end

    def yaml_body_works( out, indent:, curation_concern: )
      @total_works_exported += 1
      yaml_item( out, indent, ":id:", curation_concern.id )
      yaml_item( out, indent, ":admin_set_id:", curation_concern.admin_set_id, escape: true )
      yaml_item( out, indent, ":edit_users:", curation_concern.edit_users, escape: true )
      yaml_item_prior_identifier( out, indent, curation_concern: curation_concern )
      yaml_item_rights( out, indent, curation_concern: curation_concern )
      yaml_item_subject( out, indent, curation_concern: curation_concern )
      yaml_item( out, indent, ":total_file_count:", curation_concern.file_set_ids.count )
      yaml_item( out, indent, ":total_file_size:", curation_concern.total_file_size )
      yaml_item( out,
                 indent,
                 ":total_file_size_human_readable:",
                 human_readable_size( curation_concern.total_file_size ),
                 escape: true )
      yaml_item( out, indent, ":visibility:", curation_concern.visibility )
      skip = %w[ prior_identifier rights rights_license subject subject_discipline total_file_size ]
      attribute_names_work.each do |name|
        next if skip.include? name
        yaml_item_work( out, indent, curation_concern, name: name )
      end
    end

    def yaml_escape_value( value, comment: false, escape: false )
      return "" if value.nil?
      return value unless escape
      return value if comment
      value = value.to_json
      return "" if "\"\"" == value
      return value
    end

    def yaml_export_file_path( target_dirname:, file_set: )
      export_file_name = yaml_export_file_name( file_set: file_set )
      target_dirname.join "#{file_set.id}_#{export_file_name}"
    end

    def yaml_export_file_name( file_set: )
      title = file_set.title[0]
      file = MetadataHelper.file_from_file_set( file_set )
      if file.nil?
        rv = "nil_file"
      else
        rv = file&.original_name
        rv = "nil_original_file" if rv.nil?
      end
      rv = title unless title == rv
      rv = rv.gsub( /[\/\?\<\>\\\:\*\|\'\"\^\;]/, '_' )
      return rv
    end

    def yaml_file_set_checksum( file_set: )
      file = MetadataHelper.file_from_file_set( file_set )
      return file.checksum if file.present?
      return nil
    end

    def yaml_file_set_id( file_set )
      "f_#{file_set.id}"
    end

    def yaml_filename( pathname_dir:, id:, prefix:, task: )
      pathname_dir = Pathname.new pathname_dir unless pathname_dir.is_a? Pathname
      pathname_dir.join "#{prefix}#{id}_#{task}.yml"
    end

    def yaml_filename_collection( pathname_dir:, collection:, task: MetadataHelper::DEFAULT_TASK )
      yaml_filename( pathname_dir: pathname_dir, id: collection.id, prefix: MetadataHelper::PREFIX_COLLECTION, task: task )
    end

    def yaml_filename_users( pathname_dir:, task: MetadataHelper::DEFAULT_TASK )
      yaml_filename( pathname_dir: pathname_dir, id: '', prefix: MetadataHelper::PREFIX_USERS, task: task )
    end

    def yaml_filename_work( pathname_dir:, work:, task: MetadataHelper::DEFAULT_TASK )
      yaml_filename( pathname_dir: pathname_dir, id: work.id, prefix: MetadataHelper::PREFIX_WORK, task: task )
    end

    def yaml_header( out, indent:, curation_concern:, header_type: )
      yaml_line( out, indent, ':email:', curation_concern.depositor )
      yaml_line( out, indent, ':visibility:', curation_concern.visibility )
      yaml_line( out, indent, ':ingester:', '' )
      yaml_line( out, indent, ':source:', source )
      yaml_line( out, indent, ':export_timestamp:', DateTime.now.to_s )
      yaml_line( out, indent, ':mode:', mode )
      yaml_line( out, indent, ':id:', curation_concern.id )
      yaml_line( out, indent, header_type )
    end

    def yaml_header_populate( out, indent:, rake_task: 'umrdr:populate', target_filename: )
      yaml_line( out, indent, target_filename.to_s, comment: true )
      yaml_line( out, indent, "bundle exec rake #{rake_task}[#{target_filename}]", comment: true )
      yaml_line( out, indent, "---" )
      yaml_line( out, indent, ':user:' )
    end

    def yaml_header_users( out, indent:, header_type: MetadataHelper::HEADER_TYPE_USERS )
      yaml_line( out, indent, ':ingester:', '' )
      yaml_line( out, indent, ':source:', source )
      yaml_line( out, indent, ':export_timestamp:', DateTime.now.to_s )
      yaml_line( out, indent, ':mode:', mode )
      yaml_line( out, indent, header_type )
    end

    def yaml_is_a_work?( curation_concern: )
      if source == MetadataHelper::SOURCE_DBDv2
        curation_concern.is_a? DataSet
      else
        curation_concern.is_a? GenericWork
      end
    end

    def yaml_item( out,
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

    def yaml_item_collection( out, indent, curation_concern, name: )
      return if MetadataHelper::ATTRIBUTE_NAMES_IGNORE.include? name
      label = ":#{name}:"
      value = curation_concern[name]
      return if value.blank? && !MetadataHelper::ATTRIBUTE_NAMES_ALWAYS_INCLUDE_CC.include?( name )
      yaml_item( out, indent, label, value, escape: true )
    end

    def yaml_item_file_set( out, indent, file_set, name: )
      return if MetadataHelper::ATTRIBUTE_NAMES_IGNORE.include? name
      label = ":#{name}:"
      value = file_set[name]
      return if value.blank? && !MetadataHelper::ATTRIBUTE_NAMES_ALWAYS_INCLUDE_FILE_SET.include?( name )
      yaml_item( out, indent, label, value, escape: true )
    end

    def yaml_item_prior_identifier( out, indent, curation_concern: )
      if source == MetadataHelper::SOURCE_DBDv1
        yaml_item( out, indent, ":prior_identifier:", '' )
      else
        # ids = curation_concern.prior_identifier
        # ids = [] if ids.nil?
        # ids << curation_concern.id
        # yaml_item( out, indent, ':prior_identifier:', ActiveSupport::JSON.encode( ids ) )
        yaml_item( out, indent, ":prior_identifier:", curation_concern.prior_identifier )
      end
    end

    def yaml_item_referenced_by( out, indent, curation_concern: )
      if source == MetadataHelper::SOURCE_DBDv1
        yaml_item( out, indent, ":isReferencedBy:", curation_concern.isReferencedBy, escape: true )
      else
        yaml_item( out, indent, ":referenced_by:", curation_concern.referenced_by, escape: true )
      end
    end

    def yaml_item_rights( out, indent, curation_concern: )
      if source == MetadataHelper::SOURCE_DBDv1
        yaml_item( out, indent, ":rights:", curation_concern.rights, escape: true )
      else
        yaml_item( out, indent, ":rights_license:", curation_concern.rights_license, escape: true )
      end
    end

    def yaml_item_subject( out, indent, curation_concern: )
      if source == MetadataHelper::SOURCE_DBDv1
        yaml_item( out, indent, ":subject:", curation_concern.subject, escape: true )
      else
        yaml_item( out, indent, ":subject_discipline:", curation_concern.subject_discipline, escape: true )
      end
    end

    def yaml_item_user( out, indent, user, name: )
      return if MetadataHelper::ATTRIBUTE_NAMES_USER_IGNORE.include? name
      label = ":#{name}:"
      value = user[name]
      return if value.blank? && !MetadataHelper::ATTRIBUTE_NAMES_ALWAYS_INCLUDE_USER.include?( name )
      yaml_item( out, indent, label, value, escape: true )
    end

    def yaml_item_work( out, indent, curation_concern, name: )
      return if MetadataHelper::ATTRIBUTE_NAMES_IGNORE.include? name
      label = ":#{name}:"
      value = curation_concern[name]
      return if value.blank? && !MetadataHelper::ATTRIBUTE_NAMES_ALWAYS_INCLUDE_CC.include?( name )
      yaml_item( out, indent, label, value, escape: true )
    end

    def yaml_line( out, indent, label, value = '', comment: false, label_postfix: ' ', escape: false )
      indent = "# #{indent}" if comment
      out.puts "#{indent}#{label}#{label_postfix}#{yaml_escape_value( value, comment: comment, escape: escape )}"
    end

    def yaml_populate_collection( collection:,
                                  dir: MetadataHelper::DEFAULT_BASE_DIR,
                                  out: nil,
                                  populate_works: true,
                                  export_files: true,
                                  target_filename: nil,
                                  target_dirname: nil )

      target_file = nil
      dir = Pathname.new dir unless dir.is_a? Pathname
      if out.nil?
        collection = Collection.find collection if collection.is_a? String
        target_file = yaml_filename_collection( pathname_dir: dir, collection: collection )
        target_dir = yaml_targetdir_collection( pathname_dir: dir, collection: collection )
        Dir.mkdir( target_dir ) if export_files && !Dir.exist?( target_dir )
        open( target_file, 'w' ) do |out2|
          yaml_populate_collection( collection: collection,
                                    out: out2,
                                    populate_works: populate_works,
                                    export_files: false,
                                    target_filename: target_file,
                                    target_dirname: target_dir )
        end
        if export_files
          collection.member_objects.each do |work|
            next unless yaml_is_a_work?( curation_concern: work )
            yaml_work_export_files( work: work, target_dirname: target_dir )
          end
        end
      else
        log_provenance_migrate( curation_concern: collection ) if MetadataHelper::MODE_MIGRATE == mode
        indent_base = " " * 2
        indent = indent_base * 0
        yaml_header_populate( out, indent: indent, target_filename: target_filename )
        indent = indent_base * 1
        yaml_header( out,
                     indent: indent,
                     curation_concern: collection,
                     header_type: MetadataHelper::HEADER_TYPE_COLLECTIONS )
        indent = indent_base * 2
        yaml_body_collections( out, indent: indent, curation_concern: collection )
        return unless populate_works
        return unless collection.member_objects.size.positive?
        indent = indent_base * 2
        yaml_line( out, indent, MetadataHelper::HEADER_TYPE_WORKS )
        indent = indent_base + indent + "-"
        collection.member_objects.each do |work|
          next unless yaml_is_a_work?( curation_concern: work )
          yaml_item( out, indent, '', work.id, escape: true )
        end
        indent = indent_base * 2
        collection.member_objects.each do |work|
          next unless yaml_is_a_work?( curation_concern: work )
          indent = indent_base * 2
          yaml_line( out, indent, ":works_#{work.id}:" )
          indent = indent_base * 3
          log_provenance_migrate( curation_concern: work, parent: collection ) if MetadataHelper::MODE_MIGRATE == mode
          yaml_body_works( out, indent: indent, curation_concern: work )
          yaml_body_files( out,
                           indent_base: indent_base,
                           indent: indent,
                           curation_concern: work,
                           target_dirname: target_dirname )
        end
      end
    end

    def yaml_populate_stats
      stats = {}
      stats[:total_collections_exported] = @total_collections_exported
      stats[:total_works_exported] = @total_works_exported
      stats[:total_file_sets_exported] = @total_file_sets_exported
      stats[:total_file_sets_size_exported] = @total_file_sets_size_exported
      stats[:total_file_sets_size_readable_exported] = human_readable_size @total_file_sets_size_exported
      stats[:total_users_exported] = @total_users_exported
      return stats
    end

    def yaml_populate_users( dir: MetadataHelper::DEFAULT_BASE_DIR, out: nil, target_filename: nil )
      target_file = nil
      dir = Pathname.new dir unless dir.is_a? Pathname
      Dir.mkdir( dir ) unless Dir.exist? dir
      if out.nil?
        target_file = yaml_filename_users( pathname_dir: dir, task: mode )
        open( target_file, 'w' ) do |out2|
          yaml_populate_users( out: out2, target_filename: target_file )
        end
      else
        # log_provenance_migrate( curation_concern: curation_concern ) if MetadataHelper::MODE_MIGRATE == mode
        indent_base = " " * 2
        indent = indent_base * 0
        yaml_header_populate( out, indent: indent, rake_task: 'umrdr:populate_users', target_filename: target_filename )
        indent = indent_base * 1
        yaml_header_users( out, indent: indent )
        indent = indent_base * 2
        users = User.all
        yaml_body_users( out, indent_base: indent_base, indent: indent, users: users )
        users.each do |user|
          yaml_body_user_body( out, indent_base: indent_base, indent: indent, user: user )
        end
      end
      return target_file
    end

    def yaml_populate_work( curation_concern:,
                            dir: MetadataHelper::DEFAULT_BASE_DIR,
                            out: nil,
                            export_files: true,
                            target_filename: nil,
                            target_dirname: nil )

      target_file = nil
      dir = Pathname.new dir unless dir.is_a? Pathname
      if out.nil?
        curation_concern = yaml_work_find( curation_concern: curation_concern ) if curation_concern.is_a? String
        target_file = yaml_filename_work( pathname_dir: dir, work: curation_concern )
        target_dir = yaml_targetdir_work( pathname_dir: dir, work: curation_concern )
        Dir.mkdir( target_dir ) if export_files && !Dir.exist?( target_dir )
        open( target_file, 'w' ) do |out2|
          yaml_populate_work( curation_concern: curation_concern,
                              out: out2,
                              export_files: export_files,
                              target_filename: target_file,
                              target_dirname: target_dir )
        end
        if export_files
          yaml_work_export_files( work: curation_concern, target_dirname: target_dir )
        end
      else
        log_provenance_migrate( curation_concern: curation_concern ) if MetadataHelper::MODE_MIGRATE == mode
        indent_base = " " * 2
        indent = indent_base * 0
        yaml_header_populate( out, indent: indent, target_filename: target_filename )
        indent = indent_base * 1
        yaml_header( out,
                     indent: indent,
                     curation_concern: curation_concern,
                     header_type: MetadataHelper::HEADER_TYPE_WORKS )
        indent = indent_base * 2
        yaml_body_works( out, indent: indent, curation_concern: curation_concern )
        yaml_body_files( out,
                         indent_base: indent_base,
                         indent: indent,
                         curation_concern: curation_concern,
                         target_dirname: target_dirname )
      end
      return target_file
    end

    def yaml_targetdir( pathname_dir:, id:, prefix:, task: )
      pathname_dir = Pathname.new pathname_dir unless pathname_dir.is_a? Pathname
      pathname_dir.join "#{prefix}#{id}_#{task}"
    end

    def yaml_targetdir_collection( pathname_dir:, collection:, task: MetadataHelper::DEFAULT_TASK )
      yaml_targetdir( pathname_dir: pathname_dir, id: collection.id, prefix: MetadataHelper::PREFIX_COLLECTION, task: task )
    end

    def yaml_targetdir_users( pathname_dir:, task: MetadataHelper::DEFAULT_TASK )
      yaml_targetdir( pathname_dir: pathname_dir, id: '', prefix: MetadataHelper::PREFIX_USERS, task: task )
    end

    def yaml_targetdir_work( pathname_dir:, work:, task: MetadataHelper::DEFAULT_TASK )
      yaml_targetdir( pathname_dir: pathname_dir, id: work.id, prefix: MetadataHelper::PREFIX_WORK, task: task )
    end

    def yaml_user_email( user )
      "user_#{user.email}"
    end

    def yaml_work_export_files( work:, target_dirname: nil, log_filename: nil )
      log_file = target_dirname.join ".export.log" if log_filename.nil?
      open( log_file, 'w' ) { |f| f.write('') } # erase log file
      start_time = Time.now
      log_lines( log_file,
                 "Starting yaml work export of files at #{start_time} ...",
                 "Generic work id: #{work.id}",
                 "Total file count: #{work.file_sets.count}")
      total_byte_count = 0
      if work.file_sets.count.positive?
        work.file_sets.each do |file_set|
          export_file_name = yaml_export_file_path( target_dirname: target_dirname, file_set: file_set )
          write_file = if overwrite_export_files
                         true
                       else
                         !File.exist?( export_file_name )
                       end
          file = MetadataHelper.file_from_file_set( file_set )
          file_size = if file_set.file_size.blank?
                        file_set.original_file.nil? ? 0 : file_set.original_file.size
                      else
                        file_set.file_size[0]
                      end
          export_what = "#{export_file_name} (#{human_readable_size(file_size)} / #{file_size} bytes)"
          if write_file && file.present?
            source_uri = file.uri.value
            log_lines( log_file, "Starting file export of #{export_what} at #{Time.now}." )
            bytes_copied = ExportFilesHelper.export_file_uri( source_uri: source_uri, target_file: export_file_name )
            total_byte_count += bytes_copied
            log_lines( log_file, "Finished file export of #{export_what} at #{Time.now}." )
          elsif write_file && file.nil? && export_file_name.present?
            if create_zero_length_files
              log_lines( log_file, "File export of file_set #{file_set.id} -- #{export_what} at #{Time.now} creating zero length file because file is nil." )
              open( export_file_name, 'w' ) { |out| out.write( '' ) }
            else
              log_lines( log_file, "WARNING: Skipping file export of file_set #{file_set.id} -- #{export_what} at #{Time.now} because file is nil." )
            end
          elsif write_file && file.nil?
            log_lines( log_file, "WARNING: Skipping file export of file_set #{file_set.id} -- #{export_what} at #{Time.now} because file is nil and export_file_name is empty." )
          else
            log_lines( log_file, "Skipping file export of #{export_what} at #{Time.now}." )
          end
        end
      end
      end_time = Time.now
      log_lines( log_file,
                 "Total bytes exported: #{total_byte_count} (#{human_readable_size(total_byte_count)})",
                 "... finished yaml generic work export of files at #{end_time}.")
    rescue Exception => e # rubocop:disable Lint/RescueException
      # rubocop:disable Rails/Output
      puts "#{e.class}: #{e.message} at #{e.backtrace.join("\n")}"
      # rubocop:enable Rails/Output
    end

    def yaml_work_find( curation_concern: )
      if source == MetadataHelper::SOURCE_DBDv2
        DataSet.find curation_concern
      else
        GenericWork.find curation_concern
      end
    end

    def self.init_attribute_names_always_include_cc
      rv = {}
      MetadataHelper::ATTRIBUTE_NAMES_ALWAYS_INCLUDE_CC.each { |name| rv[name] = true }
      return rv
    end

    protected

      def attribute_names_always_include_cc
        @@attribute_names_always_include ||= init_attribute_names_always_include_cc
      end

      def attribute_names_collection
        @@attribute_names_collection ||= Collection.attribute_names.sort
      end

      def attribute_names_file_set
        @@attribute_names_file_set ||= FileSet.attribute_names.sort
      end

      def attribute_names_user
        @@attribute_names_user ||= User.attribute_names.sort
      end

      def attribute_names_work
        if source == MetadataHelper::SOURCE_DBDv2
          DataSet.attribute_names.sort
        else
          GenericWork.attribute_names.sort
        end
      end

      def file_from_file_set( file_set )
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

      def human_readable_size( value )
        value = value.to_i
        return ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert( value, precision: 3 )
      end

      def log_lines( filename, *lines )
        File.open( filename, "a" ) do |f|
          lines.each { |line| f.puts line }
        end
      end

      def log_provenance_migrate( curation_concern:, parent: nil, migrate_direction: 'export' )
        if source == MetadataHelper::SOURCE_DBDv1
          msg = "Migrate #{migrate_direction} #{curation_concern.class.name} #{curation_concern.id}"
          msg += " parent_id: #{parent.id}" if parent.present?
          PROV_LOGGER.info( msg )
        else
          return unless curation_concern.respond_to? :provenance_migrate
          parent_id = nil
          parent_id = parent.id if parent.present?
          curation_concern.provenance_migrate( current_user: nil,
                                               parent_id: parent_id,
                                               migrate_direction: migrate_direction )
        end
      end

      def metadata_filename_collection( pathname_dir, collection )
        pathname_dir.join "w_#{collection.id}_metadata_report.txt"
      end

      def metadata_filename_collection_work( pathname_dir, collection, work )
        pathname_dir.join "c_#{collection.id}_w_#{work.id}_metadata_report.txt"
      end

      def metadata_filename_work( pathname_dir, work )
        pathname_dir.join "w_#{work.id}_metadata_report.txt"
      end

      def metadata_multi_valued?( attribute_value )
        return false if attribute_value.blank?
        return true if attribute_value.respond_to?( :each ) && 1 < attribute_value.size
        false
      end

  end

end
