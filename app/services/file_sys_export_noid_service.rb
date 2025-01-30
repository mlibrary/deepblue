# frozen_string_literal: true

class FileSysExportNoidService

  mattr_accessor :file_sys_export_noid_service_debug_verbose, default: false

  attr_reader   :base_path_published
  attr_reader   :base_path_unpublished
  attr_reader   :export_type
  attr_reader   :file_sys_export
  attr_accessor :file_exporter
  attr_reader   :noid
  attr_reader   :work
  attr_accessor :msg_handler
  attr_reader   :options

  attr_reader   :exported_file_names_to_id
  attr_reader   :exported_file_ids_to_name

  attr_accessor :force_export, :skip_export, :test_mode

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

  def initialize( export_service:, noid: nil, work: nil, options: nil )
    @options               = ::Deepblue::OptionsMap.new( map: options )
    @msg_handler           = export_service.msg_handler
    @base_path_published   = export_service.base_path_published
    @base_path_unpublished = export_service.base_path_unpublished
    @export_type           = export_service.export_type
    @noid        = noid
    @work        = work
    if @work.present?
      @noid = work.id
    elsif @noid.present?
      @work = PersistHelper.find_or_nil( @noid )
      raise ArgumentError "Unable to find work for #{@noid}" unless @work.present?
    else
      raise ArgumentError "Either work or noid must be specified."
    end
    @skip_export           = @options.option_value( :skip_export,        default_value: false, msg_handler: @msg_handler )
    @force_export          = @options.option_value( :force_export,       default_value: false, msg_handler: @msg_handler )
    @test_mode             = @options.option_value( :test_mode,          default_value: false, msg_handler: @msg_handler )
    @file_sys_export = init_file_sys_export
    @file_exporter = FileSysExportNoidFiles.new( export_service: self, file_sys_export: @file_sys_export )
    @exported_file_names_to_id = {}
    @exported_file_ids_to_name = {}
  end

  def init_file_sys_export
    bold_debug [ here, called_from, "@export_type=#{@export_type}", "@work.id=#{@work}" ] if debug_verbose
    rv = FileSysExport.find_or_create_from_cc( cc: @work, export_type: @export_type )
    bold_debug [ here, called_from, "rv=#{rv}" ] if debug_verbose
    return rv
  end

  # def export_file_name( file_set: )
  #   if @exported_file_ids_to_name.has_key?( file_set.id )
  #     rv_file_name = @exported_file_ids_to_name[file_set.id]
  #   else
  #     rv_file_name = ::Deepblue::ExportFilesHelper.export_file_sets_fix_file_name( file_set: file_set,
  #                                                                                  files_extracted: @exported_file_names_to_id )
  #     @exported_file_ids_to_name[file_set.id] = rv_file_name
  #   end
  #   return rv_file_name
  # end

  def file_path( fs_rec: )
    file_path = fs_rec.file_path
    file_path = if work.published?
                  File.join( base_path_published, file_path )
                else
                  File.join( base_path_published, file_path )
                end
    return file_path
  end

  def ingest_filename()
    return "w_#{work.id}_populate.yml"
  end

  def metadata_report_filename()
    return ::FileSysExportC::METADATA_REPORT_FILENAME
  end

  def provenance_log_filename()
    return "w_#{work.id}_provenance.log"
  end

  def noid_path
    rv = FileSysExportService.path_noid( published: file_sys_export.published,
                                         base_path_published: base_path_published,
                                         base_path_unpublished: base_path_unpublished,
                                         noid: file_sys_export.noid )
    return rv
  end

  def published?
    @work.published?
  end

  def file_needs_export?( fs_rec: )
    export_status = fs_rec.export_status
    return true if export_status.blank?
    return true if FileSysExportC::STATUS_EXPORT_NEEDED
    file_path = file_path( fs_rec: fs_rec )
    rv = !File.exist?( file_path )
    return rv
  end

  def needs_export?
    return true if force_export
    FileSysExportService.data_set_needs_export?( export_type: @export_type,
                                                 cc: @work,
                                                 export_rec: @file_sys_export,
                                                 msg_handler: @msg_handler )
  end

  def needs_update_export?
    return true if force_export
    FileSysExportService.data_set_needs_export_update?( export_type: @export_type,
                                                        cc: @work,
                                                        export_rec: @file_sys_export,
                                                        msg_handler: @msg_handler )
  end

  def export_status
    @file_sys_export.export_status
  end

  def status!( export_status:, note: nil )
    @file_sys_export.export_status = export_status
    @file_sys_export.export_status_timestamp = DateTime.now
    @file_sys_export.note = note if note.present?
    @file_sys_export.save!
  end

end
