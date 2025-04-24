# frozen_string_literal: true

module FileSysExport::FileSysExportControllerBehavior

  mattr_accessor :file_sys_exports_controller_behavior_debug_verbose, default: true

  attr_accessor :begin_date, :end_date
  attr_accessor :noid
  attr_accessor :file_sys_export_id
  attr_accessor :file_sys_exports
  attr_accessor :file_exports

  def status_list
    @status_list ||= status_list_init
  end

  def status_list_init
    [ 'All' ] + ::FileSysExportC::ALL_STATUS_EXPORT.values
  end

  def index_with_commit( commit: )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "commit=#{commit}",
                                           "" ] if file_sys_exports_controller_behavior_debug_verbose
    if 'All' == commit
      init_file_sys_exports
    elsif ::FileSysExportC::ALL_STATUS_EXPORT_MAP.has_key?( commit )
      status_export = ::FileSysExportC::ALL_STATUS_EXPORT_MAP[commit]
      init_file_sys_exports( export_status: status_export )
    else
      init_file_sys_exports
    end
    # case commit
    # when 'All'
    #   init_file_sys_exports
    # when 'Deleted'
    #   init_file_sys_exports( export_status: ::FileSysExportC::STATUS_DELETED )
    # when 'Export Error'
    #   init_file_sys_exports( export_status: ::FileSysExportC::STATUS_EXPORT_ERROR )
    # when 'Export Needed'
    #   init_file_sys_exports( export_status: ::FileSysExportC::STATUS_EXPORT_NEEDED )
    # when 'Export Skipped'
    #   init_file_sys_exports( export_status: ::FileSysExportC::STATUS_EXPORT_SKIPPED )
    # when 'Export Updating'
    #   init_file_sys_exports( export_status: ::FileSysExportC::STATUS_EXPORT_UPDATING )
    # when 'Exported'
    #   init_file_sys_exports( export_status: ::FileSysExportC::STATUS_EXPORTED )
    # when 'Exporting'
    #   init_file_sys_exports( export_status: ::FileSysExportC::STATUS_EXPORTING )
    # else
    #   init_file_sys_exports
    # end
  end

  def init_begin_end_dates
    @begin_date = ViewHelper.to_date(params[:begin_date])
    @begin_date ||= Date.today - 1.week
    @end_date = ViewHelper.to_date(params[:end_date])
    @end_date ||= Date.tomorrow
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@begin_date=#{@begin_date}",
                                           "@end_date=#{@end_date}",
                                           "" ] if file_sys_exports_controller_behavior_debug_verbose
  end

  def init_file_sys_export
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if file_sys_exports_controller_behavior_debug_verbose
    init_file_sys_export_id
    @file_exports = ::FileExport.where( file_sys_exports_id: @file_sys_export_id ).order( updated_at: :desc )
    @file_sys_exports = ::FileSysExport.where( id: @file_sys_export_id )
  end

  def init_file_sys_exports( export_status: nil, not_export_status: nil )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           # "params=#{params}",
                                           "export_status=#{export_status}",
                                           "not_export_status=#{not_export_status}",
                                           "" ] if file_sys_exports_controller_behavior_debug_verbose
    init_begin_end_dates
    @file_sys_exports = if export_status.blank? && not_export_status.blank?
                        ::FileSysExport.where( [ 'updated_at >= ? AND updated_at <= ?', begin_date, end_date ] )
                             .order( updated_at: :desc )
                      elsif not_export_status.blank?
                        ::FileSysExport.where( [ 'updated_at >= ? AND updated_at <= ?', begin_date, end_date ] )
                             .where( export_status: export_status )
                             .order( updated_at: :desc )
                      elsif export_status.blank?
                        ::FileSysExport.where( [ 'updated_at >= ? AND updated_at <= ?', begin_date, end_date ] )
                             .where.not( export_status: not_export_status )
                             .order( updated_at: :desc )
                      else
                        ::FileSysExport.where( [ 'updated_at >= ? AND updated_at <= ?', begin_date, end_date ] )
                             .where( export_status: export_status )
                             .where.not( export_status: not_export_status )
                             .order( updated_at: :desc )
                      end
  end

  def init_file_sys_status_exported
    raise CanCan::AccessDenied unless current_ability.admin?
    init_file_sys_exports( export_status: ::FileSysExportC::STATUS_EXPORTED )
    # render 'file_sys_export/index'
  end

  def init_file_sys_status_exported_not
    raise CanCan::AccessDenied unless current_ability.admin?
    init_file_sys_exports( not_export_status: ::FileSysExportC::STATUS_EXPORTED )
    # render 'file_sys_export/index'
  end

  def init_file_sys_status_exporting
    raise CanCan::AccessDenied unless current_ability.admin?
    init_file_sys_exports( export_status: ::FileSysExportC::STATUS_EXPORTING )
    # render 'file_sys_export/index'
  end

  def init_file_sys_status_error
    raise CanCan::AccessDenied unless current_ability.admin?
    init_file_sys_exports( export_status: ::FileSysExportC::STATUS_EXPORT_ERROR )
    # render 'file_sys_export/index'
  end

  def init_file_sys_export_id()
    @file_sys_export_id = params[:file_sys_export_id]
  end

  # Only allow a list of trusted parameters through.
  def file_sys_export_params
    params.fetch(:file_sys_export, {})
  end

  def set_date_range
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "params[:begin_date]=#{params[:begin_date]}",
                                           "params[:end_date]=#{params[:end_date]}",
                                           "" ] if file_sys_exports_controller_behavior_debug_verbose
    @begin_date = ViewHelper.to_date(params[:begin_date])
    @begin_date ||= Date.today - 1.week
    @end_date = ViewHelper.to_date(params[:end_date])
    @end_date ||= Date.tomorrow
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@begin_date=#{@begin_date}",
                                           "@end_date=#{@end_date}",
                                           "" ] if file_sys_exports_controller_behavior_debug_verbose
  end

  def set_file_sys_export
    @file_sys_export = ::FileSysExport.find(params[:id])
  end

end
