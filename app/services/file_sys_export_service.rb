# frozen_string_literal: true

module FileSysExportService

  mattr_accessor :file_sys_export_service_debug_verbose, default: false
  mattr_accessor :data_den_base_path, default: FileSysExportIntegrationService.data_den_base_path

  def self.checksum_clear_validation( fs_rec:, save: true )
    fs_rec.checksum_validated = nil
    fs_rec.save! if save
  end

  def self.checksum_validate( fs_rec:, file_path:, msg_handler: )
    debug_verbose = msg_handler.debug_verbose
    return unless fs_rec.checksum_algorithm.present?
    return unless fs_rec.checksum_value.present?
    checksum_clear_validation( fs_rec: fs_rec )
    algorithm = fs_rec.checksum_algorithm
    fs_checksum = fs_rec.checksum_value
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "algorithm=#{algorithm}",
                             "fs_checksum=#{fs_checksum}" ] if debug_verbose
    # TODO: deal with non-SHA1 algorithms
    checksum_rv = Digest::SHA1.file file_path
    if checksum_rv == fs_checksum
      fs_rec.checksum_validated = DateTime.now
      fs_rec.save!
    else
      # TODO
    end
  end

  def self.data_set_delete( work: nil, noid: nil )
    # TODO
  end

  def self.rv_msg_verbose_if( rv, msg, msg_handler = nil )
    return rv if msg_handler.nil? || !msg_handler.verbose
    msg_handler.msg_verbose msg
    return rv
  end

  def self.rv_msg_debug_verbose_if( rv, msg, msg_handler = nil )
    return rv if msg_handler.nil? || !msg_handler.debug_verbose
    msg_handler.msg_debug msg
    return rv
  end

  def self.data_set_needs_export?( export_type:, cc:, export_rec: nil, msg_handler: nil )
    debug_verbose = msg_handler.nil? ? false : msg_handler.debug_verbose
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "export_type=#{export_type}", "cc.id=#{cc.id}" ] if debug_verbose
    export_rec = FileSysExport.find_or_create_from_cc( export_type: export_type, cc: cc ) if export_rec.nil?
    export_status = export_rec.export_status
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "export_status=#{export_status}" ] if debug_verbose
    return rv_msg_verbose_if( true, "needs export? export_status is blank", msg_handler ) if export_status.blank?
    return rv_msg_verbose_if( true, "needs export? export needed",          msg_handler ) if export_status == FileSysExportC::STATUS_EXPORT_NEEDED
    return rv_msg_verbose_if( true, "needs export? date modified newer",    msg_handler ) if cc.date_modified > export_rec.export_status_timestamp
    # TODO: other statuses?
    # TODO: check for missing and extra?
    return rv_msg_verbose_if( false, "needs export? default false", msg_handler )
  end

  def self.data_set_needs_export_update?( export_type:, cc:, export_rec: nil, msg_handler: nil )
    debug_verbose = msg_handler.nil? ? false : msg_handler.debug_verbose
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "export_type=#{export_type}", "cc.id=#{cc.id}" ] if debug_verbose
    export_rec = FileSysExport.find_or_create_from_cc( export_type: export_type, cc: cc ) if export_rec.nil?
    export_status = export_rec.export_status
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "export_status=#{export_status}" ] if debug_verbose
    return rv_msg_verbose_if( true, "needs export? export_status is blank", msg_handler ) if export_status.blank?
    return rv_msg_verbose_if( true, "needs export? export needed",          msg_handler ) if export_status == FileSysExportC::STATUS_EXPORT_NEEDED
    return rv_msg_verbose_if( true, "needs export? re-export needed",       msg_handler ) if export_status == FileSysExportC::STATUS_REEXPORT
    return rv_msg_verbose_if( true, "needs export? date modified newer",    msg_handler ) if cc.date_modified > export_rec.export_status_timestamp
    # TODO: other statuses?
    # TODO: check for missing and extra?
    return rv_msg_verbose_if( false, "needs export? default false", msg_handler )
  end

  def self.delete_all_files( service:, update_status: true )
    service.all_fs_exports.each do |fs_rec|
      fs_rec_file_delete( service: service, fs_rec: fs_rec )
      service.fs_status_export_needed( fs_rec ) if update_status
    end
  end

  def self.export_file_name_for( file_sys_export_noid_files:, export_file_name:, file_rec:, save: true )
    msg_handler = file_sys_export_noid_files.msg_handler
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from ] if msg_handler.debug_verbose
    rec_export_file_name = file_rec.export_file_name
    return rec_export_file_name if rec_export_file_name.present?
    file_export_name_map = file_sys_export_noid_files.file_export_name_map
    unless file_sys_export_noid_files.file_export_name_map.has_key?( export_file_name )
      file_rec.export_file_name = export_file_name
      file_rec.save if save
      file_sys_export_noid_files.add_to_file_export_map( file_rec: file_rec )
      return export_file_name
    end
    dup_count = 1
    new_export_file_name = ::Deepblue::ExportFilesHelper.export_file_name_increment( file_name: export_file_name,
                                                                                     count: dup_count )
    while file_export_name_map.has_key?( new_export_file_name )
      dup_count += 1
      new_export_file_name = ::Deepblue::ExportFilesHelper.export_file_name_increment( file_name: export_file_name,
                                                                                       count: dup_count )
    end
    file_rec.export_file_name = new_export_file_name
    file_rec.save if save
    file_sys_export_noid_files.add_to_file_export_map( file_rec: file_rec )
    return new_export_file_name
  end

  def self.export_file_name_for_fs( file_sys_export_noid_files:, file_set:, file_rec:, save: true )
    msg_handler = file_sys_export_noid_files.msg_handler
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from ] if msg_handler.debug_verbose
    rec_export_file_name = file_rec.export_file_name
    return rec_export_file_name if rec_export_file_name.present?
    export_file_name = ::Deepblue::ExportFilesHelper.export_file_name_fs( file_set: file_set )
    return export_file_name_for( file_sys_export_noid_files: file_sys_export_noid_files,
                                 export_file_name: export_file_name,
                                 file_rec: file_rec,
                                 save: save )
  end

  # def self.file_set_needs_export?( export_rec:, fs_rec: )
  #   export_rec = FileSysExportNoidService.find_or_create( export_type: export_type, cc: cc ) if export_rec.nil?
  #   export_status = export_rec.export_status
  #   return true if export_status.blank?
  #   return true if export_status == FileSysExportC::STATUS_EXPORT_NEEDED
  #   return true if cc.date_modified > export_rec.updated_at
  #   # TODO: other statuses?
  #   return false
  # end

  def self.file_set_delete( service:, work_service:, fs: nil, fs_noid: nil )
    return unless service.present?
    fs_rec = file_export_for( service: service, fs: fs, fs_noid: fs_noid )
    return if fs_rec.nil?
    fs_rec_delete( service: service, work_service: work_service, fs_rec: fs_rec )
  end

  def self.file_set_file_delete( service:, fs: nil, fs_noid: nil, published: )
    return 0 unless service.present?
    fs_rec = file_export_for( service: service, fs: fs, fs_noid: fs_noid )
    return 0 if fs_rec.nil?
    return fs_rec_file_delete( service: service, fs_rec: fs_rec )
  end

  def self.file_export_for( service:, fs: nil, fs_noid: nil )
    raise ArgumentError "expect fs or fs_noid to not be nil" if work.nil? && noid.nil?
    fs_noid = fs.id if fs_noid.nil?
    rec = FileExport.where( export_type: service.export_type, noid: fs_noid )
    return nil if rec.blank? || rec.empty?
    return rec.first
  end

  def self.file_sys_export_for( service:, work: nil, noid: nil )
    raise ArgumentError "expect work or noid to not be nil" if work.nil? && noid.nil?
    noid = work.id if noid.nil?
    rec = FileSysExport.where( export_type: service.export_type, noid: noid )
    return nil if rec.blank? || rec.empty?
    return rec.first
  end

  def self.fs_rec_delete( service:, work_service:, fs_rec: )
    return if fs_rec.nil?
    # TODO: look in published and unpublished for the file, delete it either or both places
    # TODO: delete the fs_rec from export_work
    # TODO: delete the fs_rec
  end

  def self.fs_rec_file_delete( service:, fs_rec: )
    files_deleted = 0
    return files_deleted unless service.present?
    return files_deleted if fs_rec.nil?
    file_path = service.resolve_file_path( fs_rec: fs_rec, published: true )
    # TODO: delete the file at file_path
    file_path = service.resolve_file_path( fs_rec: fs_rec, published: false )
    # TODO: delete the file at file_path
    return files_deleted
  end

  def self.pair_path( noid: )
    return nil unless noid.present?
    rv  = noid.split('').each_slice(2).map(&:join).join('/') + "/"
    return rv
  end

  def self.pair_path_cc( curation_concern: )
    return nil unless curation_concern.present?
    pair_path( noid: curation_concern.id )
  end

  def self.path( published:, base_path_published:, base_path_unpublished: )
    rv = if published
           base_path_published
         else
           base_path_unpublished
         end
    return rv
  end

  def self.path_noid( published:, base_path_published:, base_path_unpublished:, noid: )
    rv = path( published: published,
               base_path_published: base_path_published,
               base_path_unpublished: base_path_unpublished )
    noid_path = pair_path( noid: noid )
    rv = File.join( rv, noid_path )
    return rv
  end

  def self.report_all( service:, options: nil, msg_handler: nil )
    options = ::Deepblue::OptionsMap.options_map( map: options )
    options.value( :report_file_name, default_value: "%date%.%hostname%.all_exports.csv" ) # set default in options
    report_file_path = report_file_path( service: service, options: options, msg_handler: msg_handler )

    report_mode = options.value( :report_mode, default_value: "csv" )
    case report_mode
    when "csv"
      CSV.open( report_file_path, 'w', {:force_quotes=>true} ) do |csv|
        FileSysExport.csv_row( nil ) # header
        service.all_exports.each do |record|
          FileSysExport.csv_row( record )
        end
      end
    when "txt"

    else

    end
  end

  def self.report_all_fs( service:, options: nil, msg_handler: nil )
    options = ::Deepblue::OptionsMap.options_map( map: options )
    options.value( :report_file_name, default_value: "%date%.%hostname%.all_fs_exports.csv" ) # set default in options
    report_file_path = report_file_path( service: service, options: options, msg_handler: msg_handler )

    report_mode = options.value( :report_mode, default_value: "csv" )
    case report_mode
    when "csv"
      CSV.open( report_file_path, 'w', {:force_quotes=>true} ) do |csv|
        FileExport.csv_row( nil ) # header
        service.all_fs_exports.each do |record|
          FileExport.csv_row( record )
        end
      end
    when "txt"

    else

    end
  end

  def self.report_file_path( service:, options: nil, msg_handler: nil )
    report_path = options.value( :report_path, default_value: "./data/reports/" )
    FileUtils.mkpath( report_path ) unless File.directory?( report_path )
    report_file_name = options.value( :report_file_name, default_value: "%date%.%hostname%.all_exports.csv" )
    report_file_name = ::Deepblue::ReportHelper.expand_path_partials report_file_name
    report_file_path = File.join( report_path, report_file_name )
    report_file_path = File.absolute_path report_file_path
    msg_handler.msg_debug( [ msg_handler.here, msg_handler.called_from,
                             "report_file_path=#{report_file_path}" ] ) if msg_handler.present?
    return report_file_path
  end

end
