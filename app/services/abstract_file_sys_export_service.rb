# frozen_string_literal: true

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

  def export_all
    bold_debug [ here, called_from ] if debug_verbose
    msg_verbose "export_all starting..." if verbose
    DataSet.all.each do |work|
      noid_service = FileSysExportNoidService.new( export_service: self, work: work, options: options )
      export_data_set_rec( noid_service: noid_service )
    end
    msg_verbose "export_all starting..." if verbose
  rescue Exception => e
    Rails.logger.error "#{e.class} -- #{e.message} at #{e.backtrace[0]}"
    bold_error [ here, called_from,
                 "AbstractFileSysExportService.export_all #{e.class}: #{e.message} at #{e.backtrace[0]}" ] + e.backtrace # error
    raise
  end

  def export_data_set( work: )
    msg_verbose "export_data_set starting..." if verbose
    noid_service = FileSysExportNoidService.new( export_service: self, work: work, options: options )
    export_data_set_rec( noid_service: noid_service )
    msg_verbose "export_data_set starting..." if verbose
  rescue Exception => e
    Rails.logger.error "#{e.class} -- #{e.message} at #{e.backtrace[0]}"
    bold_error [ here, called_from,
                 "AbstractFileSysExportService.export_data_set(#{work&.id}) #{e.class}: #{e.message} at #{e.backtrace[0]}" ] + e.backtrace # error
    raise
  end

  def export_data_set_rec( noid_service: )
    bold_debug [ here, called_from, "noid_service=#{noid_service}" ] if debug_verbose
    return unless noid_service.needs_export?
    msg_verbose "exporting work #{noid_service.noid}" if verbose
    work_status_exporting( noid_service )
    export_files = noid_service.files
    noid_service.work.file_sets.each do |file_set|
      bold_debug [ here, called_from, "noid_service.noid=#{noid_service.noid}", "file_set.id=#{file_set&.id}" ] if debug_verbose
      if file_set.nil?
        msg_warn "Found nil file set for work #{noid_service.noid}"
        next
      end
      fs_rec = export_files.find_fs_record( fs: file_set )
      fs_rec = export_files.add( fs: file_set ) if fs_rec.nil?
      export_file_set_rec( noid_service: noid_service, fs: file_set, fs_rec: fs_rec )
    end
    work_status_exported( noid_service )
  rescue Exception => e
    msg_error "#{e}"
    work_status_error( noid_service, note: e.message )
    raise
  end

  def export_file_set_rec( noid_service:, fs:, fs_rec: )
    return unless noid_service.file_needs_export? fs_rec: fs_rec
    # msg_verbose "fs_rec: '#{fs_rec.pretty_inspect}'" if verbose
    path = FileSysExportService.path( published: noid_service.published?,
                                      base_path_published: @base_path_published,
                                      base_path_unpublished: @base_path_unpublished )
    msg_debug "export path: '#{path}'" if verbose_debug
    path = File.join path, fs_rec.base_noid_path
    msg_debug "export path: '#{path}'" if verbose_debug
    file_path = File.join path, fs_rec.export_file_name
    bold_debug [ here, called_from, "fs_rec.noid=#{fs_rec.noid}", "path=#{path}", "file_path=#{file_path}" ] if debug_verbose
    return fs_status_skipped( fs_rec ) if @skip_export
    fs_status_exporting( fs_rec )
    fs_file = ::Deepblue::MetadataHelper.file_from_file_set( fs )
    if fs_file.present?
      source_uri = fs_file.uri.value
      unless Dir.exist? path
        msg_verbose "mkdir_p #{path}"
        FileUtils.mkdir_p path
      end
      msg_verbose "export target_path=#{file_path}" if verbose
      bytes_copied = ::Deepblue::ExportFilesHelper.export_file_uri( source_uri: source_uri, target_file: file_path )
      msg_debug "bytes_copied: #{bytes_copied}" if debug_verbose
    else
      return fs_status_error( fs_rec, note: "file_from_file_set returned nil" )
    end
    rv = fs_status_exported( fs_rec )
    # fs_rec.export_status = FileSysExportC::STATUS_EXPORTED
    # fs_rec.export_status_timestamp = DateTime.now
    # fs_rec.save!
    rv = FileSysExportC::STATUS_EXPORTED
    FileSysExportService.checksum_validate( fs_rec: fs_rec, file_path: file_path, msg_handler: @msg_handler )
    return rv
  end

  def export_fs_status( rec, export_status, note: nil )
    bold_debug [ here, called_from, "rec=#{rec.pretty_inspect}", "export_status=#{export_status}", "test_mode=#{test_mode}" ] if debug_verbose
    msg_verbose "set fs export status for #{rec.noid} to '#{export_status}'" if verbose
    return export_status if test_mode
    # rec.status!( export_status, with_note: note ) # appears not to work
    rec.export_status = export_status
    rec.export_status_timestamp = DateTime.now
    rec.note = note if note.present?
    rec.save!
    return export_status
  end

  def noid_service_status( noid_service, export_status, note: nil )
    bold_debug [ here, called_from, "noid_service=#{noid_service}", "export_status=#{export_status}", "test_mode=#{test_mode}" ] if debug_verbose
    msg_verbose "set work export status for #{noid_service.noid} to '#{export_status}'" if verbose
    return export_status if test_mode
    noid_service.status!( export_status: export_status, note: note )
    return export_status
  end

  def export_file_set( noid_service:, fs: )
    fs_rec = export_files.find_fs_record( fs: fs )
    export_file_set_rec( noid_service: noid_service, fs: fs, fs_rec: fs_rec )
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
      rv = File.join base_path_published, rv
    else
      rv = File.join base_path_unpublished, rv
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

  def validate_checksums=( value )
    @options[:validate_checksums] = value
    @validate_checksums = value
  end

  def work_status_error(     rec, note: nil ) noid_service_status( rec, FileSysExportC::STATUS_EXPORT_ERROR,   note: note ) end
  def work_status_export_needed( rec, note: nil ) export_fs_status( rec, FileSysExportC::STATUS_EXPORT_NEEDED, note: note ) end
  def work_status_exported(  rec, note: nil ) noid_service_status( rec, FileSysExportC::STATUS_EXPORTED,       note: note ) end
  def work_status_exporting( rec, note: nil ) noid_service_status( rec, FileSysExportC::STATUS_EXPORTING,      note: note ) end
  def work_status_skipped(   rec, note: nil ) noid_service_status( rec, FileSysExportC::STATUS_EXPORT_SKIPPED, note: note ) end

end
