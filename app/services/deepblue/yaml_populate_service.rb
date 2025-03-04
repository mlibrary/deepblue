# frozen_string_literal: true

module Deepblue

  class YamlPopulateService

    DEBUG_VERBOSE                           = false unless const_defined? :DEBUG_VERBOSE

    DEFAULT_COLLECT_EXPORTED_FILE_SET_FILES = false unless const_defined? :DEFAULT_COLLECT_EXPORTED_FILE_SET_FILES
    DEFAULT_CREATE_ZERO_LENGTH_FILES        = true  unless const_defined? :DEFAULT_CREATE_ZERO_LENGTH_FILES
    DEFAULT_OVERWRITE_EXPORT_FILES          = true  unless const_defined? :DEFAULT_OVERWRITE_EXPORT_FILES
    DEFAULT_VALIDATE_FILE_CHECKSUMS         = false unless const_defined? :DEFAULT_VALIDATE_FILE_CHECKSUMS

    # options
    attr_accessor :collect_exported_file_set_files
    attr_accessor :create_zero_length_files
    attr_accessor :debug_verbose
    attr_accessor :export_includes_callback
    attr_accessor :mode
    attr_accessor :msg_handler
    attr_accessor :overwrite_export_files
    attr_accessor :source
    attr_accessor :validate_file_checksums

    # variables
    attr_accessor :errors
    attr_accessor :exported_file_set_files
    # TODO: count these
    attr_reader :total_collections_exported
    attr_reader :total_file_sets_exported
    attr_reader :total_works_exported
    attr_reader :total_users_exported

    def initialize( collect_exported_file_set_files: DEFAULT_COLLECT_EXPORTED_FILE_SET_FILES,
                    create_zero_length_files:        DEFAULT_CREATE_ZERO_LENGTH_FILES,
                    mode:                            MetadataHelper::MODE_BUILD,
                    msg_handler:                     nil,
                    overwrite_export_files:          DEFAULT_OVERWRITE_EXPORT_FILES,
                    source:                          MetadataHelper::DEFAULT_SOURCE,
                    validate_file_checksums:         DEFAULT_VALIDATE_FILE_CHECKSUMS,
                    export_includes_callback:        nil,
                    debug_verbose:                   DEBUG_VERBOSE )

      # options
      @debug_verbose                   = debug_verbose
      @collect_exported_file_set_files = collect_exported_file_set_files
      @create_zero_length_files        = create_zero_length_files
      @mode                            = mode
      @msg_handler                     = msg_handler
      @overwrite_export_files          = overwrite_export_files
      @source                          = source
      @validate_file_checksums         = validate_file_checksums
      @export_includes_callback        = export_includes_callback

      @msg_handler ||= MessageHandlerNull.new
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "@create_zero_length_files=#{@create_zero_length_files}",
                               "@export_files=#{@export_files}",
                               "@export_files_newer_than_date=#{@export_files_newer_than_date}",
                               "@mode=#{@mode}",
                               "@overwrite_export_files=#{@overwrite_export_files}",
                               "@target_dir=#{@target_dir}",
                               "@validate_file_checksums=#{@validate_file_checksums}",
                             ] if debug_verbose

      @exported_file_set_files       = []
      @errors                        = []
      @total_collections_exported    = 0
      @total_file_sets_exported      = 0
      @total_file_sets_size_exported = 0
      @total_works_exported          = 0
      @total_users_exported          = 0
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
        export_file_name = yaml_export_file_path( target_dirname: target_dirname, file_set: file_set )
        export_parent = File.dirname export_file_name
        # puts "export_parent=#{export_parent}"
        # puts `ls -l #{export_parent}`
        file_id_base = yaml_file_set_id( file_set )
        file_id = ":#{file_id_base}:"
        yaml_line( out, indent_first_line, file_id )
        indent = indent_base + indent_first_line
        yaml_item( out, indent, ':id:', file_set.id, escape: true )
        single_value = 1 == file_set.title.size
        yaml_item( out, indent, ':title:', file_set.title, escape: true, single_value: single_value )
        yaml_item_prior_identifier( out, indent, curation_concern: file_set )
        file_path = yaml_import_file_path( target_dirname: target_dirname, file_set: file_set )
        filename = File.basename file_path
        yaml_item( out, indent, ':file_path:', file_path.to_s, escape: true )
        # checksum = yaml_file_set_checksum( file_set: file_set )
        # yaml_item( out, indent, ":checksum_algorithm:", checksum.present? ? checksum.algorithm : '', escape: true )
        # yaml_item( out, indent, ":checksum_value:", checksum.present? ? checksum.value : '', escape: true )
        # yaml_item( out, indent, ":checksum_algorithm:", checksum.algorithm, escape: true )
        # yaml_item( out, indent, ":checksum_value:", checksum.value, escape: true )
        yaml_item( out, indent, ":edit_users:", file_set.edit_users, escape: true )
        file_size = MetadataHelper.file_set_file_size file_set
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

        # original = file_set.original_file
        # versions = original ? original.versions.all : []
        versions = file_set.versions
        yaml_item( out, indent, ":version_count:", versions.count )
        if versions.count > 1
          versions.each_with_index do |ver,index|
            index += 1 # not zero-based
            next if index >= versions.count # skip exporting last version file as it is the current version
            yaml_item( out, indent, ":version#{index}:" )
            # yaml_item( out, indent + indent_base, ":version_id:", ver.uri )
            vc = Hyrax::VersionCommitter.where( version_id: ver.uri )
            if vc.empty?
              yaml_item( out, indent + indent_base, ":version_committer:", '' )
              yaml_item( out, indent + indent_base, ":created_at:", '' )
              yaml_item( out, indent + indent_base, ":updated_at:", '' )
              yaml_item( out, indent + indent_base, ":file_name:", '' )
              yaml_item( out, indent + indent_base, ":file_size:", '' )
              yaml_item( out, indent + indent_base, ":checksum_algorithm:", '' )
              yaml_item( out, indent + indent_base, ":checksum_value:", '' )
            else
              vc = vc.first
              yaml_item( out, indent + indent_base, ":version_committer:", vc.committer_login )
              yaml_item( out, indent + indent_base, ":created_at:", vc.created_at )
              yaml_item( out, indent + indent_base, ":updated_at:", vc.updated_at )
              v_filename = "v#{index}_#{filename}"
              # puts "v_filename=#{v_filename}"
              v_exported_file = File.join export_parent, v_filename
              # puts "v_exported_file=#{v_exported_file} --> exist? #{File.exist? v_exported_file}"
              yaml_item( out, indent + indent_base, ":file_name:", v_filename )
              if File.exist? v_exported_file
                # puts "File.size? v_exported_file=#{File.size? v_exported_file}"
                file_size = File.size? v_exported_file
                yaml_item( out, indent + indent_base, ":file_size:", file_size )
                checksum,algo = yaml_compute_checksum_in_chunks v_exported_file
                yaml_item( out, indent + indent_base, ":checksum_algorithm:", algo )
                yaml_item( out, indent + indent_base, ":checksum_value:", checksum )
              else
                yaml_item( out, indent + indent_base, ":file_size:", '' )
                yaml_item( out, indent + indent_base, ":checksum_algorithm:", '' )
                yaml_item( out, indent + indent_base, ":checksum_value:", '' )
              end
            end
          end
        end

        skip = %w[ prior_identifier title file_size ]
        attribute_names_file_set.each do |name|
          next if skip.include? name
          yaml_item_file_set( out, indent, file_set, name: name )
        end
      end
    end

    def yaml_compute_checksum_in_chunks(file)
      checksum = File.open( file, 'rb' ) do |io|
        Digest::SHA1.new.tap do |checksum|
          while chunk = io.read(5.megabytes)
            checksum << chunk
          end
        end.hexdigest
      end
      return checksum,'SHA1'
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
      yaml_item( out, indent, ":state:", curation_concern.state_str )
      yaml_item( out, indent, ":visibility:", curation_concern.visibility )
      yaml_item( out, indent, ":workflow_state:", curation_concern.workflow_state )
      skip = %w[ admin_set_id prior_identifier rights rights_license subject subject_discipline total_file_size ]
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
      # export_file_name = yaml_export_file_name( file_set: file_set )
      # filename = "#{file_set.id}_#{export_file_name}"
      filename = ::Deepblue::ExportFilesHelper.export_file_name_fs( file_set: file_set, include_id: true )
      puts filename if DEBUG_VERBOSE
      target_dirname.join filename
     end

    def yaml_import_file_path( target_dirname:, file_set: )
      # export_file_name = yaml_export_file_name( file_set: file_set )
      # filename = "#{file_set.id}_#{export_file_name}"
      filename = ::Deepblue::ExportFilesHelper.export_file_name_fs( file_set: file_set, include_id: true )
      puts filename if DEBUG_VERBOSE
      if MetadataHelper::MODE_BAG == mode
        filename = File.basename filename
        File.join ".", filename
      else
        target_dirname.join filename
      end
    end

    # def yaml_export_file_name( file_set: )
    #   title = file_set.title[0]
    #   file = MetadataHelper.file_from_file_set( file_set )
    #   if file.nil?
    #     rv = "nil_file"
    #   else
    #     rv = file&.original_name
    #     rv = "nil_original_file" if rv.nil?
    #   end
    #   rv = title unless title == rv
    #   rv = rv.gsub( /[\/\?\<\>\\\:\*\|\'\"\^\;]/, '_' )
    #   return rv
    # end

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
      rv = pathname_dir.join "#{prefix}#{id}_#{task}.yml"
      puts "yaml_filename( pathname_dir: #{pathname_dir}, id: #{id}, prefix: #{prefix}, task: #{task} )" if DEBUG_VERBOSE
      puts "rv=#{rv}" if DEBUG_VERBOSE
      return rv
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

    def yaml_header_populate( out, indent:, rake_task: 'deepblue:append', target_filename: )
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
                                  export_files_newer_than_date: nil,
                                  target_filename: nil,
                                  target_dirname: nil )

      target_file = nil
      dir = Pathname.new dir unless dir.is_a? Pathname
      if out.nil?
        collection = Collection.find collection if collection.is_a? String
        target_file = yaml_filename_collection( pathname_dir: dir, collection: collection )
        target_dir = yaml_targetdir_collection( pathname_dir: dir, collection: collection )
        Dir.mkdir( target_dir ) if export_files && !Dir.exist?( target_dir )
        File.open( target_file, 'w' ) do |out2|
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
            yaml_work_export_files( work: work,
                                    export_files_newer_than_date: export_files_newer_than_date,
                                    target_dirname: target_dir )
          end
        end
      else
        log_provenance_migrate( curation_concern: collection ) if MetadataHelper::MODE_MIGRATE == mode
        indent_base = " " * 2
        indent = indent_base * 0
        yaml_header_populate( out, indent: indent, rake_task: "deepblue:#{mode}", target_filename: target_filename )
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
        File.open( target_file, 'w' ) do |out2|
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

    def yaml_populate_work( curation_concern:         ,
                            dir:                      MetadataHelper::DEFAULT_BASE_DIR,
                            out:                      nil,
                            export_files:             true,
                            export_files_newer_than_date: nil,
                            target_filename:          nil,
                            target_dirname:           nil,
                            log_filename:             nil )

      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "curation_concern.nil?=#{curation_concern.nil?}",
                               "dir=#{dir}",
                               "out.nil?=#{out.nil?}",
                               "export_files=#{export_files}",
                               "export_files_newer_than_date=#{export_files_newer_than_date}",
                               "target_filename=#{target_filename}",
                               "target_dirname=#{target_dirname}",
                               "log_filename=#{log_filename}",
                               "" ] if debug_verbose
      target_file = nil
      dir = Pathname.new dir unless dir.is_a? Pathname
      # puts "dir=#{dir}" if debug_verbose
      if out.nil?
        msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from ] if debug_verbose
        curation_concern = yaml_work_find( curation_concern: curation_concern ) if curation_concern.is_a? String
        target_file = yaml_filename_work( pathname_dir: dir, work: curation_concern )
        target_dir = yaml_targetdir_work( pathname_dir: dir, work: curation_concern )
        # Dir.mkdir( target_dir ) if export_files && !Dir.exist?( target_dir )
        if export_files
          msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from ] if debug_verbose
          Dir.mkdir( target_dir ) unless Dir.exist?( target_dir )
          yaml_work_export_files( work: curation_concern,
                                  export_files_newer_than_date: export_files_newer_than_date,
                                  target_dirname: target_dir,
                                  log_filename: log_filename )
        end
        File.open( target_file, 'w' ) do |out2|
          yaml_populate_work( curation_concern:         curation_concern,
                              out:                      out2,
                              export_files:             export_files,
                              export_files_newer_than_date: export_files_newer_than_date,
                              target_filename:          target_file,
                              target_dirname:           target_dir )
        end
        # if export_files
        #   yaml_work_export_files( work: curation_concern,
        #                           export_files_newer_than_date: export_files_newer_than_date,
        #                           target_dirname: target_dir,
        #                           log_filename: log_filename )
        # end
      else
        msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from ] if debug_verbose
        log_provenance_migrate( curation_concern: curation_concern ) if MetadataHelper::MODE_MIGRATE == mode
        indent_base = " " * 2
        indent = indent_base * 0
        yaml_header_populate( out, indent: indent, rake_task: "deepblue:#{mode}", target_filename: target_filename )
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
      if MetadataHelper::MODE_BAG == mode
        rv = pathname_dir
      else
        rv = pathname_dir.join "#{prefix}#{id}_#{task}"
      end
      puts "yaml_targetdir( pathname_dir: #{pathname_dir}, id: #{id}, prefix: #{prefix}, task: #{task} )" if DEBUG_VERBOSE
      puts "rv=#{rv}" if DEBUG_VERBOSE
      return rv
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

    def yaml_validate_file_set_checksum_build( file_set: )
      return nil unless validate_file_checksums
      rv = { algorithm: file_set.checksum_algorithm, checksum: file_set.checksum_value }
      return rv
    end

    def yaml_work_export_file( file_set:, log_file:, target_dir: )
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "file_set=#{file_set.id}",
                               "log_file=#{log_file}",
                               "target_dir=#{target_dir}",
                               "" ] if debug_verbose
      bytes_exported = 0
      export_file_name = yaml_export_file_path( target_dirname: target_dir, file_set: file_set )
      exported_file_set_files << export_file_name if collect_exported_file_set_files
      write_file = if overwrite_export_files
                     true
                   else
                     !File.exist?( export_file_name )
                   end
      file = MetadataHelper.file_from_file_set( file_set )
      export_what = yaml_export_log_file( file_set, export_file_name )
      if write_file && file.present?
        source_uri = file.uri.value
        log_lines( log_file, "Starting file export of #{export_what} at #{Time.now}." )
        validate_with_checksum = yaml_validate_file_set_checksum_build( file_set: file_set )
        log_lines_from_export = []
        bytes_copied = ExportFilesHelper.export_file_uri( source_uri: source_uri,
                                                          target_file: export_file_name,
                                                          validate_with_checksum: validate_with_checksum,
                                                          log_lines: log_lines_from_export,
                                                          errors: @errors,
                                                          debug_verbose: debug_verbose )
        log_lines( log_file, log_lines_from_export ) if log_lines_from_export.present?
        bytes_exported += bytes_copied
        log_lines( log_file, "Finished file export of #{export_what} at #{Time.now}." )
      elsif write_file && file.nil? && export_file_name.present?
        if create_zero_length_files
          log_lines( log_file,
                     "File export of file_set #{file_set.id} -- #{export_what}" +
                     " at #{Time.now} creating zero length file because file is nil." )
          File.open( export_file_name, 'w' ) { |out| out.write( '' ) }
        else
          log_lines( log_file,
                     "WARNING: Skipping file export of file_set #{file_set.id} -- #{export_what}" +
                     " at #{Time.now} because file is nil." )
        end
      elsif write_file && file.nil?
        log_lines( log_file,
                   "WARNING: Skipping file export of file_set #{file_set.id} -- #{export_what}" +
                   " at #{Time.now} because file is nil and export_file_name is empty." )
      else
        log_lines( log_file, "Skipping file export of #{export_what} at #{Time.now}." )
      end
      # original = file_set.original_file
      # versions = original ? original.versions.all : []
      versions = file_set.versions
      filename = File.basename export_file_name
      if versions.count > 1
        versions.each_with_index do |ver,index|
          index += 1 # not zero-based
          next if index >= versions.count # skip exporting last version file as it is the current version
          vc = Hyrax::VersionCommitter.where( version_id: ver.uri )
          if vc.empty?
            # skip
          else
            vc = vc.first
            v_filename = "v#{index}_#{filename}"
            v_filename = File.join target_dir, v_filename
            # TODO: check if overwriting, and do the right thing
            log_lines( log_file, "Starting file export of #{v_filename} at #{Time.now}." )
            bytes_copied = ExportFilesHelper.export_file_uri( source_uri: ver.uri,
                                                              target_file: v_filename,
                                                              debug_verbose: debug_verbose )
            bytes_exported += bytes_copied
            log_lines( log_file, "Finished file export of #{v_filename} at #{Time.now}." )
          end
        end
      end
      return bytes_exported
    end

    def yaml_export_log_file( file_set, export_file_name )
      file_size = if file_set.file_size.blank?
                    file_set.original_file.nil? ? 0 : file_set.original_file.size
                  else
                    file_set.file_size[0]
                  end
      "#{export_file_name} (#{human_readable_size(file_size)} / #{file_size} bytes)"
    end

    def yaml_work_export_files( work:,
                                export_files_newer_than_date: nil,
                                target_dirname: nil,
                                log_filename: nil )

      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "work.nil?=#{work.nil?}",
                               "export_files_newer_than_date=#{export_files_newer_than_date}",
                               "target_dirname=#{target_dirname}",
                               "" ] if debug_verbose
      log_filename ||= "w_#{work.id}.export.log"
      log_file = target_dirname.join log_filename
      File.open( log_file, 'w' ) { |f| f.write('') } # erase log file
      start_time = Time.now
      log_lines( log_file,
                 "Starting yaml work export of files at #{start_time} ...",
                 "Generic work id: #{work.id}",
                 "Total file count: #{work.file_sets.count}")
      total_byte_count = 0
      if work.file_sets.count.positive?
        test_to_include = export_includes_callback
        work.file_sets.each do |file_set|
          date_modified = file_set.date_modified
          msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                                   "file_set.id=#{file_set.id}",
                                   "export_files_newer_than_date=#{export_files_newer_than_date}",
                                   "date_modified=#{date_modified}",
                                   "" ] if debug_verbose
          next if export_files_newer_than_date.present? && date_modified < export_files_newer_than_date
          if test_to_include.present?
            rv = test_to_include.call( file_set )
            msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                                     "file_set.id=#{file_set.id}",
                                     "test_to_include rv=#{rv}",
                                     "" ] if debug_verbose
            next unless rv
          end
          msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from ] if debug_verbose
          bytes_exported = yaml_work_export_file( file_set: file_set, log_file: log_file, target_dir: target_dirname )
          total_byte_count += bytes_exported
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
      raise
    end

    def yaml_work_find( curation_concern: )
      if source == MetadataHelper::SOURCE_DBDv2
        ::PersistHelper.find curation_concern
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
