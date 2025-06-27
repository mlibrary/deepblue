# frozen_string_literal: true

class ::FileSysExport::FileSysExportsController < ApplicationController

  include ::FileSysExport::FileSysExportControllerBehavior

  mattr_accessor :file_sys_exports_controller_debug_verbose, default: false

  include AdminOnlyControllerBehavior

  with_themed_layout 'dashboard'

  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :set_date_range #, only: %i[ index ]
  before_action :set_file_sys_export, only: %i[ show edit update destroy ]

  class_attribute :presenter_class, default: ::FileSysExport::FileSysExportsPresenter

  attr_reader :action_error

  def action
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           ">>> status action <<<",
                                           "params=#{params}",
                                           "params[:commit]=#{params[:commit]}",
                                           "" ] if file_sys_exports_controller_debug_verbose
    action = params[:commit]
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "action='#{action}'",
                                           "" ] if file_sys_exports_controller_debug_verbose
    @action_error = true
    msg = case action
          # when MsgHelper.t( 'simple_form.actions.scheduler.restart' )
          when 'Delete'
            ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                   ::Deepblue::LoggingHelper.called_from,
                                                   "" ] if file_sys_exports_controller_debug_verbose
            action_delete
          when 'Reexport'
            ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                   ::Deepblue::LoggingHelper.called_from,
                                                   "" ] if file_sys_exports_controller_debug_verbose
            action_reexport
          else
            ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                   ::Deepblue::LoggingHelper.called_from,
                                                   "" ] if file_sys_exports_controller_debug_verbose
            @action_error = true
            "Unkown action '#{action}'"
          end
    if action_error
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if file_sys_exports_controller_debug_verbose
      redirect_to file_sys_exports_path, alert: msg
    else
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if file_sys_exports_controller_debug_verbose
      redirect_to file_sys_exports_path, notice: msg
    end
  end

  def has_error
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if file_sys_exports_controller_debug_verbose
    raise CanCan::AccessDenied unless current_ability.admin?
    init_file_sys_exports_errors
    render 'file_sys_export/file_export/index'
  end

  # GET /file_sys_exports or /file_sys_exports.json
  def index
    raise CanCan::AccessDenied unless current_ability.admin?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params[:file_sys_export_id]=#{params[:file_sys_export_id]}",
                                           "params[:commit]=#{params[:commit]}",
                                           "" ] if file_sys_exports_controller_debug_verbose
    @file_sys_exports = []
    @file_exports = []
    if params[:file_sys_export_id].present?
      init_file_sys_export
    elsif params[:commit].present?
      index_with_commit( commit: params[:commit] )
    else
      init_file_sys_exports
    end
    @presenter = presenter_class.new( controller: self, current_ability: current_ability )
    render 'file_sys_export/index'
  end

  # GET /file_sys_exports/1 or /file_sys_exports/1.json
  def show
    raise CanCan::AccessDenied unless current_ability.admin?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "" ] if file_sys_exports_controller_debug_verbose
    init_begin_end_dates
    @presenter = presenter_class.new( controller: self, current_ability: current_ability )
  end

  def action_delete
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if file_sys_exports_controller_debug_verbose
    raise CanCan::AccessDenied unless current_ability.admin?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "params['id']=#{params['id']}",
                                           "params['noid']=#{params['noid']}",
                                           "" ] if file_sys_exports_controller_debug_verbose
    records = ::FileSysExport.where( id: params['id'] )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "records.size=#{records.size}",
                                           "" ] if file_sys_exports_controller_debug_verbose
    return if records.size < 1 # TODO: error
    record = records[0]
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "record.id=#{record.id}",
                                           "record.noid=#{record.noid}",
                                           "" ] if file_sys_exports_controller_debug_verbose
    record.export_status = ::FileSysExportC::STATUS_DELETED
    record.export_status_timestamp = DateTime.now
    record.note = "UI request from #{current_user.email}"
    record.save
  end

  def action_reexport
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if file_sys_exports_controller_debug_verbose
    raise CanCan::AccessDenied unless current_ability.admin?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "params['id']=#{params['id']}",
                                           "params['noid']=#{params['noid']}",
                                           "" ] if file_sys_exports_controller_debug_verbose
    records = ::FileSysExport.where( id: params['id'] )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "records.size=#{records.size}",
                                           "" ] if file_sys_exports_controller_debug_verbose
    return if records.size < 1 # TODO: error
    record = records[0]
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "record.id=#{record.id}",
                                           "record.noid=#{record.noid}",
                                           "" ] if file_sys_exports_controller_debug_verbose
    record.export_status = ::FileSysExportC::STATUS_REEXPORT
    record.export_status_timestamp = DateTime.now
    record.note = "UI request from #{current_user.email}"
    record.save
  end

  def export_status_failed
    raise CanCan::AccessDenied unless current_ability.admin?
    init_file_sys_exports( export_status: ::FileSysExportC::STATUS_EXPORT_ERROR )
    render 'file_sys_export/file_export/index'
  end

  def export_status_exported
    raise CanCan::AccessDenied unless current_ability.admin?
    init_file_sys_exports( export_status: ::FileSysExportC::STATUS_EXPORTED )
    render 'file_sys_export/file_export/index'
  end

  def export_status_not_exported
    raise CanCan::AccessDenied unless current_ability.admin?
    init_file_sys_exports( not_export_status: ::FileSysExportC::STATUS_EXPORTED )
    render 'file_sys_export/file_export/index'
  end

  def export_status_exporting
    raise CanCan::AccessDenied unless current_ability.admin?
    init_file_sys_exports( export_status: ::FileSysExportC::STATUS_EXPORTING )
    render 'file_sys_export/file_export/index'
  end

  # PATCH/PUT /file_sys_exports/1 or /file_sys_exports/1.json
  def update
    raise CanCan::AccessDenied unless current_ability.admin?
    respond_to do |format|
      if @file_sys_export.update(file_sys_export_params)
        format.html { redirect_to @file_sys_export, notice: "FileSysExport event was successfully updated." }
        format.json { render :show, export_status: :ok, location: @file_sys_export }
      else
        format.html { render :edit, event: :unprocessable_entity }
        format.json { render json: @file_sys_export.errors, event: :unprocessable_entity }
      end
    end
  end

end
