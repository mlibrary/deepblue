# frozen_string_literal: true

require_relative './deepblue/message_handler'
require_relative './deepblue/message_handler_null'
require_relative './file_sys_export_c'

class AbstractFileSysExportService

  mattr_accessor :abstract_file_sys_export_debug_verbose, default: false

  attr_reader   :base_path_published
  attr_reader   :base_path_unpublished
  attr_reader   :export_type
  attr_accessor :msg_handler
  attr_reader   :options
  attr_reader   :skip_export
  attr_reader   :test_mode
  attr_reader   :validate_checksums
  attr_reader   :force_export

  delegate :debug_verbose, :verbose, to: :msg_handler
  delegate :bold_debug,
           :bold_error,
           :here,
           :called_from,
           :msg,
           :msg_debug,
           :msg_error,
           :msg_verbose,
           :msg_warn,
           to: :msg_handler

  def init_msg_handler( msg_handler:, options: )
    msg_handler
    if msg_handler.nil?
      msg_handler_options = { debug_verbose: abstract_file_sys_export_debug_verbose }
      msg_handler         = MessageHandler.new( options: msg_handler_options )
    end
    msg_handler.verbose       = options.option_value( :verbose       ) if options.option? :verbose
    msg_handler.debug_verbose = options.option_value( :debug_verbose ) if options.option? :debug_verbose
    return msg_handler
  end

  def initialize( base_path_published:, base_path_unpublished:, export_type:, msg_handler: nil, options: nil )
    @base_path_published   = base_path_published
    @base_path_unpublished = base_path_unpublished
    @export_type           = export_type
    @options               = ::Deepblue::OptionsMap.new( map: options )
    @msg_handler           = init_msg_handler( msg_handler: msg_handler, options: @options )
    @skip_export           = @options.option_value( :skip_export,        default_value: false, msg_handler: @msg_handler )
    @force_export          = @options.option_value( :force_export,       default_value: false, msg_handler: @msg_handler )
    @test_mode             = @options.option_value( :test_mode,          default_value: false, msg_handler: @msg_handler )
    @validate_checksums    = @options.option_value( :validate_checksums, default_value: true,  msg_handler: @msg_handler )
  end

  def all_exports
    FileSysExport.where( export_type: export_type )
  end

  def all_fs_exports
    FileExport.where( export_type: export_type )
  end

  def data_set_publish( cc: )
    noid_service = FileSysExportNoidService.new( export_service: self, work: cc )
    data_set_publish_rec( noid_service: noid_service )
  end

  def data_set_publish_rec( noid_service: )
    # TODO
  end

  def data_set_unpublish( cc: )
    noid_service = FileSysExportNoidService.new( export_service: self, work: cc )
    data_set_unpublish_rec( noid_service: noid_service )
  end

  def data_set_unpublish_rec( noid_service: )
    # TODO
  end

  def data_set_update( cc:, error_if_work_record_missing: true )
    # TODO
    # TODO: get work_rec for cc
    # TODO: get file_sets_delta
    # TODO: process missing
    # TODO: process extra
  end

  def ensure_dir_exists( path: )
    unless FileUtilsHelper.dir_exist? path
      msg_verbose "mkdir_p #{path}"
      FileUtilsHelper.mkdir_p path
    end
  end

  def export_all
    # NOTE: we don't want to export if @file_sys_export.status == ::FileSysExportC::STATUS_EXPORTING
    bold_debug [ here, called_from ] if debug_verbose
    msg_verbose "export_all starting..." if verbose
    DataSet.all.each do |work|
      noid_service = FileSysExportNoidService.new( export_service: self, work: work, options: options )
      export_data_set_rec( noid_service: noid_service )
    end
    msg_verbose "export_all finished." if verbose
  rescue Exception => e
    Rails.logger.error "#{e.class} -- #{e.message} at #{e.backtrace[0]}"
    bold_error [ here, called_from,
                 "AbstractFileSysExportService.export_all #{e.class}: #{e.message} at #{e.backtrace[0]}" ] + e.backtrace # error
    raise
  end

  def export_data_set( work: nil, noid: nil )
    # NOTE: we don't want to export if @file_sys_export.status == ::FileSysExportC::STATUS_EXPORTING
    msg_verbose "export_data_set starting..." if verbose
    raise ArgumentError( "Expected one of work or noid to not be nil." ) if work.nil? && noid.nil?
    work = PersistHelper.find_or_nil( noid ) if work.nil?
    raise ArgumentError( "Could not find data set #{noid}" ) if work.nil?
    noid_service = FileSysExportNoidService.new( export_service: self, work: work, options: options )
    export_data_set_rec( noid_service: noid_service )
    msg_verbose "export_data_set finished." if verbose
  rescue Exception => e
    Rails.logger.error "#{e.class} -- #{e.message} at #{e.backtrace[0]}"
    bold_error [ here, called_from,
                 "AbstractFileSysExportService.export_data_set(#{work&.id}) #{e.class}: #{e.message} at #{e.backtrace[0]}" ] + e.backtrace # error
    raise
  end

  def export_data_set_clean_rec( noid_service: )
    # TODO: delete files and records
  end

  def export_data_set_rec( noid_service: )
    bold_debug [ here, called_from, "noid_service=#{noid_service}" ] if debug_verbose
    return unless noid_service.needs_export?
    msg_verbose "exporting work #{noid_service.noid}" if verbose
    work_status_exporting( noid_service )
    export_metadata_file( noid_service: noid_service )
    export_provenance_file( noid_service: noid_service )
    export_ingest_file( noid_service: noid_service )
    file_exporter = noid_service.file_exporter
    noid_service.work.file_sets.each do |file_set|
      bold_debug [ here, called_from,
                   "noid_service.noid=#{noid_service.noid}",
                   "file_set.id=#{file_set&.id}" ] if debug_verbose
      if file_set.nil?
        msg_warn "Found nil file set for work #{noid_service.noid}"
        next
      end
      fs_rec = file_exporter.find_fs_record( fs: file_set )
      fs_rec = file_exporter.add_fs( fs: file_set ) if fs_rec.nil?
      export_fs_rec( noid_service: noid_service, fs: file_set, fs_rec: fs_rec )
      versions = file_set.versions
      msg_verbose "#{file_set.id}: versions.count=#{versions.count}" if verbose
      next if 2 > versions.count
      versions.each_with_index do |ver,index|
        index += 1 # not zero-based
        next if index >= versions.count # skip exporting last version file as it is the current version
        msg_verbose "#{file_set.id}: version index=#{index}" if verbose
        export_file_set_version( noid_service: noid_service, fs_rec: fs_rec, version: ver, index: index )
      end
    end
    # move published data set files to published dir
    msg_verbose "noid_service.published?=#{noid_service.published?}"
    export_data_set_publish_rec( noid_service: noid_service ) if noid_service.published?
    work_status_exported( noid_service )
  rescue Exception => e
    msg_error "#{e}"
    work_status_error( noid_service, note: e.message )
    raise
  end

  def export_data_set_publish_rec( noid_service: )
    file_exporter = noid_service.file_exporter
    file_exporter.file_recs.each do |fs_rec|
      msg_verbose "export_data_set_publish_rec fs_rec.noid=#{fs_rec.noid}" if verbose
      if ::FileSysExportC::NOIDS_KEEP_PRIVATE.has_key? fs_rec.noid
        msg_verbose "export_data_set_publish_rec skip private fs_rec.noid=#{fs_rec.noid}" if verbose
        next
      end
      if fs_rec.noid.match( /^.+\:v\d+$/ ) then
        msg_verbose "export_data_set_publish_rec skip version fs_rec.noid=#{fs_rec.noid}" if verbose
        next
      end
      move_export_rec( fs_rec: fs_rec )
    end
  end

  def export_data_set_unpublish_rec( noid_service: )
    # TODO: move files back from published directory and update records
    file_exporter = noid_service.file_exporter
    file_exporter.file_recs.each do |fs_rec|
      msg_verbose "export_data_set_publish_rec fs_rec.noid=#{fs_rec.noid}" if verbose
      if ::FileSysExportC::NOIDS_KEEP_PRIVATE.has_key? fs_rec.noid
        msg_verbose "export_data_set_unpublish_rec skip private fs_rec.noid=#{fs_rec.noid}" if verbose
        next
      end
      move_export_unpublish_rec( fs_rec: fs_rec )
    end
  end

  def export_file_set( noid_service:, file_set:, file_path: )
    id = file_set.id
    fs_file = ::Deepblue::MetadataHelper.file_from_file_set( file_set )
    return false unless fs_file.present?
    source_uri = fs_file.uri.value
    msg_verbose "#{id} export target_path=#{file_path}" if verbose
    bytes_copied = ::Deepblue::ExportFilesHelper.export_file_uri( source_uri: source_uri, target_file: file_path )
    msg_debug "#{id} bytes_copied: #{bytes_copied}" if debug_verbose
    return true
  end

  def export_fs_rec( noid_service:, fs:, fs_rec: )
    return unless noid_service.file_needs_export? fs_rec: fs_rec
    export_fs_status( fs_rec, ::FileSysExportC::STATUS_EXPORTING_PRIVATE )
    path = export_path( published: false )
    ensure_dir_exists path: path
    msg_debug "export path: '#{path}'" # if verbose_debug
    path = FileUtilsHelper.join path, fs_rec.base_noid_path
    msg_debug "export path: '#{path}'" # if verbose_debug
    file_path = FileUtilsHelper.join path, fs_rec.export_file_name
    bold_debug [ here, called_from,
                 "fs_rec.noid=#{fs_rec.noid}",
                 "path=#{path}",
                 "file_path=#{file_path}" ] if debug_verbose
    return fs_status_skipped( fs_rec ) if @skip_export
    fs_status_exporting( fs_rec )
    unless export_file_set( noid_service: noid_service, file_set: fs, file_path: file_path )
      return fs_status_error( fs_rec, note: "export_fs_rec failed" )
    end
    rv = export_fs_status( fs_rec, ::FileSysExportC::STATUS_EXPORTED_PRIVATE )
    FileSysExportService.checksum_validate( fs_rec: fs_rec, file_path: file_path, msg_handler: @msg_handler )
    return rv
  end

  def export_fs_status( rec, export_status, note: nil )
    bold_debug [ here, called_from,
                 "rec=#{rec.pretty_inspect}",
                 "export_status=#{export_status}",
                 "test_mode=#{test_mode}" ] if debug_verbose
    msg_verbose "set fs export status for #{rec.noid} to '#{export_status}'" if verbose
    return export_status if test_mode
    # rec.status!( export_status, with_note: note ) # appears not to work
    rec.export_status = export_status
    rec.export_status_timestamp = DateTime.now
    rec.note = note if note.present?
    rec.save!
    return export_status
  end

  def export_file_set_version( noid_service:, fs_rec:, index:, version: )
    noid = fs_rec.noid
    vc = Hyrax::VersionCommitter.where( version_id: version.uri )
    if vc.empty?
      msg_verbose "#{noid}: version index=#{index} is empty" if verbose
      return
    end
    vc = vc.first
    v_filename = "v#{index}_#{fs_rec.export_file_name}"
    msg_verbose "#{noid}: v_filename=#{v_filename}" if verbose
    file_exporter = noid_service.file_exporter
    v_noid = "#{noid}:v#{index}"
    v_fs_rec = file_exporter.find_noid_record( noid: v_noid )
    v_fs_rec = file_exporter.add_file( ancillary_id: v_noid, file_name: v_filename ) if v_fs_rec.nil?
    export_fs_status( v_fs_rec, ::FileSysExportC::STATUS_EXPORTING_PRIVATE )
    target_dir = export_path( published: false )
    target_dir = FileUtilsHelper.join target_dir, v_fs_rec.base_noid_path
    msg_verbose "#{noid}: version target_dir=#{target_dir}" if verbose
    ensure_dir_exists path: target_dir
    target_file = FileUtilsHelper.join target_dir, v_filename
    bytes_copied = ::Deepblue::ExportFilesHelper.export_file_uri( source_uri: version.uri, target_file: target_file )
    msg_debug "#{noid} bytes_copied: #{bytes_copied}" if debug_verbose
    rv = export_fs_status( v_fs_rec, ::FileSysExportC::STATUS_EXPORTED_PRIVATE )
  end

  def export_ingest_file( noid_service: )
    ingest_filename = noid_service.ingest_filename()
    msg_verbose "ingest_filename=#{ingest_filename}" if verbose
    file_exporter = noid_service.file_exporter
    fs_rec = file_exporter.find_noid_record( noid: ::FileSysExportC::ANCILLARY_ID_INGEST )
    fs_rec = file_exporter.add_file( ancillary_id: ::FileSysExportC::ANCILLARY_ID_INGEST,
                                    file_name: ingest_filename ) if fs_rec.nil?
    export_fs_status( fs_rec, ::FileSysExportC::STATUS_EXPORTING_PRIVATE )
    target_dir = export_path( published: false )
    target_dir = FileUtilsHelper.join target_dir, fs_rec.base_noid_path
    msg_verbose "target_dir=#{target_dir}" if verbose
    ensure_dir_exists path: target_dir
    export_work_populate_script( noid_service: noid_service, target_dir: target_dir )
    rv = export_fs_status( fs_rec, ::FileSysExportC::STATUS_EXPORTED_PRIVATE )
  end

  def export_metadata_file( noid_service: )
    metadata_filename = noid_service.metadata_report_filename()
    msg_verbose "metadata_filename=#{metadata_filename}" if verbose
    file_exporter = noid_service.file_exporter
    fs_rec = file_exporter.find_noid_record( noid: ::FileSysExportC::ANCILLARY_ID_METADATA )
    fs_rec = file_exporter.add_file( ancillary_id: ::FileSysExportC::ANCILLARY_ID_METADATA,
                                     file_name: metadata_filename ) if fs_rec.nil?
    export_fs_status( fs_rec, ::FileSysExportC::STATUS_EXPORTING_PRIVATE )
    target_dir = export_path( published: false )
    target_dir = FileUtilsHelper.join target_dir, fs_rec.base_noid_path
    msg_verbose "target_dir=#{target_dir}" if verbose
    ensure_dir_exists path: target_dir
    target_file = FileUtilsHelper.join target_dir, metadata_filename
    File.open( target_file, 'w' ) do |out|
      noid_service.work.metadata_report_out( out: out )
    end
    rv = export_fs_status( fs_rec, ::FileSysExportC::STATUS_EXPORTED_PRIVATE )
  end

  def export_path( published: )
    FileSysExportService.path( published: published,
                               base_path_published: @base_path_published,
                               base_path_unpublished: @base_path_unpublished )
  end

  def export_provenance_file( noid_service: )
    # TODO: provenance file for each file set?
    provenance_log_filename = noid_service.provenance_log_filename()
    msg_verbose "provenance_log_filename=#{provenance_log_filename}" if verbose
    file_exporter = noid_service.file_exporter
    fs_rec = file_exporter.find_noid_record( noid: ::FileSysExportC::ANCILLARY_ID_PROVENANCE )
    fs_rec = file_exporter.add_file( ancillary_id: ::FileSysExportC::ANCILLARY_ID_PROVENANCE,
                                     file_name: provenance_log_filename ) if fs_rec.nil?
    export_fs_status( fs_rec, ::FileSysExportC::STATUS_EXPORTING_PRIVATE )
    target_dir = export_path( published: false )
    target_dir = FileUtilsHelper.join target_dir, fs_rec.base_noid_path
    msg_verbose "target_dir=#{target_dir}" if verbose
    ensure_dir_exists path: target_dir
    entries = ::Deepblue::ProvenanceLogService.entries( noid_service.work.id, refresh: true )
    target_file = File.join( target_dir, provenance_log_filename )
    ::Deepblue::ProvenanceLogService.write_entries( target_file, entries )
    rv = export_fs_status( fs_rec, ::FileSysExportC::STATUS_EXPORTED_PRIVATE )
  end

  def export_work_populate_script( noid_service:, target_dir: )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "target_dir=#{target_dir}" ] if debug_verbose
    verbose = msg_handler.verbose
    msg_handler.verbose = false unless debug_verbose
    pop = ::Deepblue::YamlPopulate.new( populate_type: 'work',
                                        msg_handler: msg_handler,
                                        options: { verbose:                  false,
                                                   mode:                     ::Deepblue::MetadataHelper::MODE_BUILD,
                                                   export_files:              false,
                                                   # export_files_newer_than_date: export_file_sets_filter_date,
                                                   target_dir:                target_dir,
                                                   validate_file_checksums:   false,
                                                   debug_verbose:             false } )
    pop.yaml_populate_work( id: noid_service.work.id, work: noid_service.work )
    msg_handler.verbose = verbose
  end

  def move_export_rec( fs_rec: )
    export_fs_status( fs_rec, ::FileSysExportC::STATUS_EXPORTING_PUBLIC )
    unpublished_path = export_path( published: false )
    published_path = export_path( published: true )
    unpublished_path = FileUtilsHelper.join unpublished_path, fs_rec.base_noid_path
    published_path = FileUtilsHelper.join published_path, fs_rec.base_noid_path
    msg_debug "move from path: '#{unpublished_path}'" if debug_verbose
    msg_debug "move to path: '#{published_path}'" if debug_verbose
    unpublished_path_file = FileUtilsHelper.join unpublished_path, fs_rec.export_file_name
    published_path_file = FileUtilsHelper.join published_path, fs_rec.export_file_name
    bold_debug [ here, called_from,
                 "fs_rec.noid=#{fs_rec.noid}",
                 "unpublished_path=#{unpublished_path}",
                 "unpublished_path_file=#{unpublished_path_file}",
                 "published_path=#{published_path}",
                 "published_path_file=#{published_path_file}" ] if debug_verbose
    return fs_status_skipped( fs_rec ) if @skip_export
    ensure_dir_exists path: published_path
    msg_verbose "FileUtilsHelper.mv( #{unpublished_path_file}, #{published_path} )"
    FileUtilsHelper.mv( unpublished_path_file, published_path )
    rv = export_fs_status( fs_rec, ::FileSysExportC::STATUS_EXPORTED_PUBLIC )
    # FileSysExportService.checksum_validate( fs_rec: fs_rec, file_path: published_path_file, msg_handler: @msg_handler )
    return rv
  end

  def move_export_unpublish_rec( fs_rec: )
    export_fs_status( fs_rec, ::FileSysExportC::STATUS_EXPORTING_PRIVATE )
    unpublished_path = export_path( published: false )
    published_path = export_path( published: true )
    unpublished_path = FileUtilsHelper.join unpublished_path, fs_rec.base_noid_path
    published_path = FileUtilsHelper.join published_path, fs_rec.base_noid_path
    msg_debug "move from path: '#{unpublished_path}'" if debug_verbose
    msg_debug "move to path: '#{published_path}'" if debug_verbose
    unpublished_path_file = FileUtilsHelper.join unpublished_path, fs_rec.export_file_name
    published_path_file = FileUtilsHelper.join published_path, fs_rec.export_file_name
    bold_debug [ here, called_from,
                 "fs_rec.noid=#{fs_rec.noid}",
                 "unpublished_path=#{unpublished_path}",
                 "unpublished_path_file=#{unpublished_path_file}",
                 "published_path=#{published_path}",
                 "published_path_file=#{published_path_file}" ] if debug_verbose
    return rv unless FileUtilsHelper.file_exists? published_path_file
    msg_verbose "FileUtilsHelper.mv( #{published_path_file}, #{unpublished_path} )"
    FileUtilsHelper.mv( published_path_file, unpublished_path )
    rv = export_fs_status( fs_rec, ::FileSysExportC::STATUS_EXPORTED_PRIVATE )
    return rv
  end

  def noid_service_status( noid_service, export_status, note: nil )
    bold_debug [ here, called_from,
                 "noid_service=#{noid_service}",
                 "export_status=#{export_status}",
                 "test_mode=#{test_mode}" ] if debug_verbose
    msg_verbose "set work export status for #{noid_service.noid} to '#{export_status}'" if verbose
    return export_status if test_mode
    noid_service.status!( export_status: export_status, note: note )
    return export_status
  end

  def fs_rec_file_exists?( fs_rec: )
    return false if fs_rec.nil?
    file_path = resolve_file_path( fs_rec: fs_rec, published: true )
    return true if File.exist?( file_path )
    file_path = resolve_file_path( fs_rec: fs_rec, published: false )
    return true if File.exist?( file_path )
    return false
  end

  def fs_status_error(     rec, note: nil ) export_fs_status( rec, FileSysExportC::STATUS_EXPORT_ERROR,   note: note   ) end
  def fs_status_export_needed( rec, note: nil ) export_fs_status( rec, FileSysExportC::STATUS_EXPORT_NEEDED, note: note ) end
  def fs_status_exported(  rec, note: nil ) export_fs_status( rec, FileSysExportC::STATUS_EXPORTED,       note: note   ) end
  def fs_status_exporting( rec, note: nil ) export_fs_status( rec, FileSysExportC::STATUS_EXPORTING,      note: note   ) end
  def fs_status_skipped(   rec, note: nil ) export_fs_status( rec, FileSysExportC::STATUS_EXPORT_SKIPPED, note: note   ) end

  def option_value( key, default_value: nil )
    @options.option_value( key, default_value: default_value, msg_handler: @msg_handler )
  end

  def path_export_work( export_work: )
    path = FileSysExportService.path_noid( published: export_work.published?,
                                           base_path_published: @base_path_published,
                                           base_path_unpublished: @base_path_unpublished,
                                           noid: export_work.noid )
    return path
  end

  def report_exported
    # TODO
    # loop over all file_sys_export records
  end

  def report_export_needed
    # TODO
    # loop over all file_sys_export records
  end

  def resolve_file_path( fs_rec:, published: )
    return nil if fs_rec.nil?
    rv = fs_rec.export_file_path
    if published
      rv = FileUtilsHelper.join base_path_published, rv
    else
      rv = FileUtilsHelper.join base_path_unpublished, rv
    end
    return rv
  end

  def skip_export=( value )
    @options[:skip_export] = value
    @skip_export = value
  end

  def test_mode=( value )
    @options[:test_mode] = value
    @test_mode = value
  end

  def update_export_data_set( work: )
    msg_verbose "update_export_data_set starting..." if verbose
    noid_service = FileSysExportNoidService.new( export_service: self, work: work, options: options )
    export_data_set_rec( noid_service: noid_service )
    msg_verbose "export_data_set finished." if verbose
  rescue Exception => e
    Rails.logger.error "#{e.class} -- #{e.message} at #{e.backtrace[0]}"
    bold_error [ here, called_from,
                 "AbstractFileSysExportService.update_export_data_set(#{work&.id}) #{e.class}: #{e.message} at #{e.backtrace[0]}" ] + e.backtrace # error
    raise
  end

  def update_export_data_set_rec( noid_service: )
    # NOTE: we don't want to export if @file_sys_export.status == ::FileSysExportC::STATUS_EXPORTING
    bold_debug [ here, called_from, "noid_service=#{noid_service}" ] if debug_verbose
    return unless noid_service.needs_update_export?
    msg_verbose "updating export work #{noid_service.noid}" if verbose
    work_status_export_updating( noid_service )
    export_metadata_file( noid_service: noid_service )
    export_provenance_file( noid_service: noid_service )
    export_ingest_file( noid_service: noid_service )
    file_exporter = noid_service.file_exporter
    noid_service.work.file_sets.each do |file_set|
      bold_debug [ here, called_from,
                   "noid_service.noid=#{noid_service.noid}",
                   "file_set.id=#{file_set&.id}" ] if debug_verbose
      if file_set.nil?
        msg_warn "Found nil file set for work #{noid_service.noid}"
        next
      end
      if file_exporter.needs_export_update?( file_set: file_set )
          fs_rec = file_exporter.find_fs_record( fs: file_set )
          export_fs_rec( noid_service: noid_service, fs: file_set, fs_rec: fs_rec )
          # TODO: since versions are static, we only care about ones that don't have an fs_rec
          #   versions = file_set.versions
          #   msg_verbose "#{file_set.id}: versions.count=#{versions.count}" if verbose
          #   next if 2 > versions.count
          #   versions.each_with_index do |ver,index|
          #     index += 1 # not zero-based
          #     next if index >= versions.count # skip exporting last version file as it is the current version
          #     msg_verbose "#{file_set.id}: version index=#{index}" if verbose
          #     export_file_set_version( noid_service: noid_service, fs_rec: fs_rec, version: ver, index: index )
          #   end
      end
    end
    export_data_set_publish_rec( noid_service: noid_service ) if noid_service.published?
    work_status_exported( noid_service )
  rescue Exception => e
    msg_error "#{e}"
    work_status_error( noid_service, note: e.message )
    raise
  end

  def validate_checksums=( value )
    @options[:validate_checksums] = value
    @validate_checksums = value
  end

  def work_status_error(     rec, note: nil ) noid_service_status( rec, FileSysExportC::STATUS_EXPORT_ERROR,   note: note ) end
  def work_status_export_needed( rec, note: nil ) export_fs_status( rec, FileSysExportC::STATUS_EXPORT_NEEDED, note: note ) end
  def work_status_export_updating( rec, note: nil ) noid_service_status( rec, FileSysExportC::STATUS_EXPORT_UPDAING,      note: note ) end
  def work_status_exported(  rec, note: nil ) noid_service_status( rec, FileSysExportC::STATUS_EXPORTED,       note: note ) end
  def work_status_exporting( rec, note: nil ) noid_service_status( rec, FileSysExportC::STATUS_EXPORTING,      note: note ) end
  def work_status_skipped(   rec, note: nil ) noid_service_status( rec, FileSysExportC::STATUS_EXPORT_SKIPPED, note: note ) end

end
