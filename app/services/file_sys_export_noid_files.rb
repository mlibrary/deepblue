# frozen_string_literal: true

class FileSysExportNoidFiles

  mattr_accessor :file_sys_export_noid_files_debug_verbose, default: false

  attr_reader :file_sys_export
  attr_reader :file_recs
  attr_reader :fsid_map
  attr_reader :file_export_name_map
  attr_reader :noid
  attr_reader :export_service

  delegate :msg_handler, to: :export_service

  def initialize( export_service:, file_sys_export: )
    @export_service = export_service
    @file_sys_export = file_sys_export
    @noid = file_sys_export.noid
    @file_recs = init_file_recs( msg_handler: export_service.msg_handler )
    init_maps( msg_handler: export_service.msg_handler )
  end

  def init_file_recs( msg_handler: )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from ] if msg_handler.debug_verbose
    rv = []
    records = FileExport.for_file_sys_export( file_sys_export: @file_sys_export )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "records.count=#{records.count}" ] if msg_handler.debug_verbose
    records.each do |r|
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "r.noid=#{r.noid}" ] if msg_handler.debug_verbose
      rv << r
    end
    return rv
  end

  def init_maps( msg_handler: )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from ] if msg_handler.debug_verbose
    @fsid_map = {}
    @file_export_name_map = {}
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "@file_recs.size=#{@file_recs.size}" ] if msg_handler.debug_verbose
    @file_recs.each do |file_rec|
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "file_rec.noid=#{file_rec.noid}" ] if msg_handler.debug_verbose
      @fsid_map[file_rec.noid] = file_rec
      add_to_file_export_map( file_rec: file_rec )
    end
  end

  def add_fs( fs: )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "fs.id=#{fs&.id}" ] if msg_handler.debug_verbose
    msg_handler.msg_verbose "#{msg_prefix} add fs #{fs&.id} " if msg_handler.present?
    return nil if fs.nil?
    file_rec = @fsid_map[ fs.id ]
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "file_rec.noid from fsid_map[#{fs.id}]=#{file_rec&.noid}" ] if msg_handler.debug_verbose
    return file_rec unless file_rec.nil?
    file_rec = FileExport.find_or_create_for_fs( file_sys_export: file_sys_export, fs: fs )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "#{fs.id} - file_rec.noid from after find or create=#{file_rec&.noid}" ] if msg_handler.debug_verbose
    @file_recs << file_rec
    @fsid_map[ file_rec.noid ] = file_rec
    add_export_file_name_to_file_rec_fs( file_set: fs, file_rec: file_rec, save: true )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "#{fs.id} - file_rec.noid #{file_rec.noid} - #{file_rec.export_file_path}" ] if msg_handler.debug_verbose
    return file_rec
  end

  def add_file( ancillary_id:, file_name: )
    # TODO: work
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "ancillary_id=#{ancillary_id}", "file_name=#{file_name}" ] if msg_handler.debug_verbose
    msg_handler.msg_verbose "#{msg_prefix} add ancillary_id #{ancillary_id} " if msg_handler.present?
    file_rec = @fsid_map[ ancillary_id ]
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "ancillary_id from fsid_map[#{ancillary_id}]=#{file_rec&.noid}" ] if msg_handler.debug_verbose
    return file_rec unless file_rec.nil?
    file_rec = FileExport.find_or_create( file_sys_export: file_sys_export, noid: ancillary_id )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "#{ancillary_id} - file_rec.noid from after find or create=#{file_rec&.noid}" ] if msg_handler.debug_verbose
    @file_recs << file_rec
    @fsid_map[ file_rec.noid ] = file_rec
    add_export_file_name_to_file_rec( file_name: file_name, file_rec: file_rec, save: true )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "#{ancillary_id} - file_rec.noid #{file_rec.noid} - #{file_rec.export_file_path}" ] if msg_handler.debug_verbose
    return file_rec
  end

  def add_export_file_name_to_file_rec( file_name:, file_rec:, save: true )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "file_name=#{file_name}", "file_rec.noid=#{file_rec.noid}" ] if msg_handler.debug_verbose
    export_file_name = ::Deepblue::ExportFilesHelper.export_file_name( file_name: file_name )
    rv = FileSysExportService.export_file_name_for( file_sys_export_noid_files: self,
                                                    export_file_name: export_file_name,
                                                    file_rec: file_rec,
                                                    save: save )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "rv=#{rv}" ] if msg_handler.debug_verbose
    return rv
  end

  def add_export_file_name_to_file_rec_fs( file_set:, file_rec:, save: true )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "file_set.id=#{file_set.id}", "file_rec.noid=#{file_rec.noid}" ] if msg_handler.debug_verbose
    rv = FileSysExportService.export_file_name_for_fs( file_sys_export_noid_files: self,
                                                       file_set: file_set,
                                                       file_rec: file_rec,
                                                       save: save )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "rv=#{rv}" ] if msg_handler.debug_verbose
    return rv
  end

  def add_to_file_export_map( file_rec: )
    export_file_name = file_rec.export_file_name
    return unless export_file_name.present?
    return if @file_export_name_map.has_key?( export_file_name )
    @file_export_name_map[export_file_name] = file_rec
  end

  def delete( file_rec: )
    return file_rec unless @fsid_map[ file_rec.noid ].present?
    delete!( file_rec: file_rec )
  end

  def delete!( file_rec: )
    # TODO
  end

  def delete_missing_files()
    missing_files.each do |file_rec|
      delete!( file_rec: file_rec )
    end
  end

  def export_file_name_for_fs( file_set:, file_rec:, save: true )
    rv = FileSysExportService.export_file_name_for_fs( file_sys_export_noid_files: self,
                                                       file_set: file_set,
                                                       file_rec: file_rec,
                                                       save: save )
    return rv
  end

  def file_sets_delta( file_sets: )
    missing = []
    extra = @fsid_map.dup
    file_sets.each do |fs|
      if @fsid_map[fs.id].has_key?
        extra.delete( fs.id )
      else
        missing << fs
      end
    end
    return { extra: extra, missing: missing }
  end

  def find_fs_record( fs: )
    return nil if fs.nil?
    file_rec = @fsid_map[ fs.id ]
    return file_rec
  end

  def find_noid_record( noid: )
    return nil if noid.nil?
    file_rec = @fsid_map[ noid ]
    return file_rec
  end

  def msg_prefix
    "FileSysExportNoidFiles(#{noid})"
  end

end
