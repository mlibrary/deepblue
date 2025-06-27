# frozen_string_literal: true

class ::FileSysExport::FileExportsController < ApplicationController

  include ::FileSysExport::FileSysExportControllerBehavior

  mattr_accessor :file_exports_controller_debug_verbose, default: false

  include AdminOnlyControllerBehavior

  with_themed_layout 'dashboard'

  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :set_date_range #, only: %i[ index ]
  before_action :set_file_export, only: %i[ show edit update destroy ]

  class_attribute :presenter_class, default: ::FileSysExport::FileExportsPresenter

  attr_reader :action_error

  def status_action
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           ">>> status action <<<",
                                           "params=#{params}",
                                           "params[:commit]=#{params[:commit]}",
                                           "" ] if file_exports_controller_debug_verbose
    action = params[:commit]
    @action_error = false
    msg = case action
          # when MsgHelper.t( 'simple_form.actions.scheduler.restart' )
          when 'Delete'
            ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                   ::Deepblue::LoggingHelper.called_from,
                                                   "" ] if file_exports_controller_debug_verbose
            action_delete
            #"Action #{action}"
          when 'Reexport'
            ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                   ::Deepblue::LoggingHelper.called_from,
                                                   "" ] if file_exports_controller_debug_verbose
            action_reexport
            #"Action #{action}"
          else
            ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                   ::Deepblue::LoggingHelper.called_from,
                                                   "" ] if file_exports_controller_debug_verbose
            @action_error = true
            "Unkown action #{action}"
          end
    if action_error
      redirect_to file_sys_exports_path, alert: msg
    else
      redirect_to file_sys_exports_path, notice: msg
    end
  end

  def has_error
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if file_exports_controller_debug_verbose
    raise CanCan::AccessDenied unless current_ability.admin?
    init_file_sys_exports_errors
    render 'file_sys_export/index'
  end

  # GET /file_sys_exports or /file_sys_exports.json
  def index
    raise CanCan::AccessDenied unless current_ability.admin?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params[:file_sys_export_id]=#{params[:file_sys_export_id]}",
                                           "params[:commit]=#{params[:commit]}",
                                           "" ] if file_exports_controller_debug_verbose
    @file_exports = []
    @file_sys_exports = []
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

  def set_file_export
    @file_exports = ::FileExport.find(params[:id])
  end

  def action_delete
    raise CanCan::AccessDenied unless current_ability.admin?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "params['id']=#{params['id']}",
                                           "params['noid']=#{params['noid']}",
                                           "" ] if file_exports_controller_debug_verbose
    records = ::FileSysExport.where( id: params['id'] )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "records.size=#{records.size}",
                                           "" ] if file_exports_controller_debug_verbose
    return if records.size < 1 # TODO: error
    record = records[0]
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "record.id=#{record.id}",
                                           "record.noid=#{record.noid}",
                                           "" ] if file_exports_controller_debug_verbose
    record.delete
  end

  def action_reexport
    raise CanCan::AccessDenied unless current_ability.admin?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "params['id']=#{params['id']}",
                                           "params['noid']=#{params['noid']}",
                                           "" ] if file_exports_controller_debug_verbose
    records = ::FileSysExport.where( id: params['id'] )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "records.size=#{records.size}",
                                           "" ] if file_exports_controller_debug_verbose
    return if records.size < 1 # TODO: error
    record = records[0]
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "record.id=#{record.id}",
                                           "record.noid=#{record.noid}",
                                           "" ] if file_exports_controller_debug_verbose
    record.event = ::FileSysExportC::STATUS_EVENT_REEXPORT
    record.event_note = ''
    record.timestamp = DateTime.now
    record.save
  end

  # PATCH/PUT /file_sys_exports/1 or /file_sys_exports/1.json
  def update
    # TODO
    # raise CanCan::AccessDenied unless current_ability.admin?
    # respond_to do |format|
    #   if @aptrust_status.update(aptrust_status_params)
    #     format.html { redirect_to @aptrust_status, notice: "Aptrust status was successfully updated." }
    #     format.json { render :show, event: :ok, location: @aptrust_status }
    #   else
    #     format.html { render :edit, event: :unprocessable_entity }
    #     format.json { render json: @aptrust_status.errors, event: :unprocessable_entity }
    #   end
    # end
  end

end
