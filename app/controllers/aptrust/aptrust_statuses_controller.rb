# frozen_string_literal: true

require_relative '../../services/aptrust/aptrust'

module Aptrust
class AptrustStatusesController < ApplicationController

  mattr_accessor :aptrust_statuses_controller_debug_verbose, default: true

  include AdminOnlyControllerBehavior

  with_themed_layout 'dashboard'

  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :set_date_range #, only: %i[ index ]
  before_action :set_aptrust_status, only: %i[ show edit update destroy ]

  class_attribute :presenter_class, default: ::Aptrust::AptrustStatusesPresenter

  attr_accessor :begin_date, :end_date
  attr_accessor :noid, :status_id
  attr_accessor :aptrust_events
  attr_accessor :aptrust_statuses

  attr_reader :action_error

  def status_event_list
    @status_event_list ||= [ 'All', 'Deposited', 'Exported', 'Failed', 'Finished', 'Has Error', 'Not Finished', 'Skipped', 'Started', 'Verified' ]
  end

  def status_action
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           ">>> status action <<<",
                                           "params=#{params}",
                                           "params[:commit]=#{params[:commit]}",
                                           "" ] if aptrust_statuses_controller_debug_verbose
    action = params[:commit]
    @action_error = false
    msg = case action
          # when MsgHelper.t( 'simple_form.actions.scheduler.restart' )
          when 'Delete'
            action_delete
          when 'Reupload'
            action_reupload
          else
            @action_error = true
            "Unkown action #{action}"
          end
    if action_error
      redirect_to aptrust_statuses_path, alert: msg
    else
      redirect_to aptrust_statuses_path, notice: msg
    end
  end

  def has_error
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if aptrust_statuses_controller_debug_verbose
    raise CanCan::AccessDenied unless current_ability.admin?
    init_aptrust_statuses_errors
    render 'aptrust/index'
  end

  # GET /aptrust_statuses or /aptrust_statuses.json
  def index
    raise CanCan::AccessDenied unless current_ability.admin?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params[:status_id]=#{params[:status_id]}",
                                           "params[:commit]=#{params[:commit]}",
                                           "" ] if aptrust_statuses_controller_debug_verbose
    @aptrust_events = []
    @aptrust_statuses = []
    if params[:status_id].present?
      init_aptrust_status
    elsif params[:commit].present?
      index_with_commit( commit: params[:commit] )
    else
      init_aptrust_statuses
    end
    @presenter = presenter_class.new( controller: self, current_ability: current_ability )
    render 'aptrust/index'
  end

  def index_with_commit( commit: )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "commit=#{commit}",
                                           "" ] if aptrust_statuses_controller_debug_verbose
    case commit
    when 'All'
      init_aptrust_statuses
    # when 'Delete'
    #   status_delete
    #   init_aptrust_statuses
    when 'Deposited'
      init_aptrust_statuses( event: ::Aptrust::EVENT_DEPOSITED )
    when 'Exported'
      init_aptrust_statuses( event: ::Aptrust::EVENT_EXPORTED )
    when 'Failed'
      init_aptrust_statuses( event: ::Aptrust::EVENTS_FAILED )
    when 'Finished'
      init_aptrust_statuses( event: ::Aptrust::EVENTS_FINISHED )
    when 'Has Error'
      init_aptrust_statuses( event: ::Aptrust::EVENTS_ERRORS )
    when 'Not Finished'
      init_aptrust_statuses( not_event: ::Aptrust::EVENT_EXPORTED )
    when 'Skipped'
      init_aptrust_statuses( event: ::Aptrust::EVENTS_SKIPPED )
      # init_aptrust_statuses( event: ::Aptrust::EVENT_UPLOAD_SKIPPED )
    when 'Started'
      init_aptrust_statuses( event: ::Aptrust::EVENTS_PROCESSING )
    when 'Verified'
      init_aptrust_statuses( event: ::Aptrust::EVENT_VERIFIED )
    else
      init_aptrust_statuses
    end
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
                                           "" ] if aptrust_statuses_controller_debug_verbose
  end

  def init_aptrust_statuses( event: nil, not_event: nil )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           # "params=#{params}",
                                           "event=#{event}",
                                           "not_event=#{not_event}",
                                           "" ] if aptrust_statuses_controller_debug_verbose
    init_begin_end_dates
    @aptrust_statuses = if event.blank? && not_event.blank?
                      Status.where( [ 'updated_at >= ? AND updated_at <= ?', begin_date, end_date ] )
                                     .order( updated_at: :desc )
                    elsif not_event.blank?
                      Status.where( [ 'updated_at >= ? AND updated_at <= ?', begin_date, end_date ] )
                                     .where( event: event )
                                     .order( updated_at: :desc )
                    elsif event.blank?
                      Status.where( [ 'updated_at >= ? AND updated_at <= ?', begin_date, end_date ] )
                                     .where.not( event: not_event )
                        .order( updated_at: :desc )
                    else
                      Status.where( [ 'updated_at >= ? AND updated_at <= ?', begin_date, end_date ] )
                                     .where( event: event )
                                     .where.not( event: not_event )
                                     .order( updated_at: :desc )
                    end
  end

  def init_aptrust_status
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if aptrust_statuses_controller_debug_verbose
    init_status_id
    @aptrust_statuses = Status.where( id: @status_id )
    @aptrust_events = Event.where( aptrust_status_id: @status_id ).order( updated_at: :desc )
  end

  def init_status_id()
    @status_id = params[:status_id]
  end

  # Only allow a list of trusted parameters through.
  def aptrust_status_params
    params.fetch(:aptrust_status, {})
  end

  def set_date_range
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "params[:begin_date]=#{params[:begin_date]}",
                                           "params[:end_date]=#{params[:end_date]}",
                                           "" ] if aptrust_statuses_controller_debug_verbose
    @begin_date = ViewHelper.to_date(params[:begin_date])
    @begin_date ||= Date.today - 1.week
    @end_date = ViewHelper.to_date(params[:end_date])
    @end_date ||= Date.tomorrow
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@begin_date=#{@begin_date}",
                                           "@end_date=#{@end_date}",
                                           "" ] if aptrust_statuses_controller_debug_verbose
  end

  def set_aptrust_status
    @aptrust_status = ::Aptrust::Status.find(params[:id])
  end

  def action_delete
    raise CanCan::AccessDenied unless current_ability.admin?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "params['id']=#{params['id']}",
                                           "params['noid']=#{params['noid']}",
                                           "" ] if aptrust_statuses_controller_debug_verbose
    records = ::Aptrust::Status.where( id: params['id'] )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "records.size=#{records.size}",
                                           "" ] if aptrust_statuses_controller_debug_verbose
    return if records.size < 1 # TODO: error
    record = records[0]
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "record.id=#{record.id}",
                                           "record.noid=#{record.noid}",
                                           "" ] if aptrust_statuses_controller_debug_verbose
    record.delete
  end

  def action_reupload
    raise CanCan::AccessDenied unless current_ability.admin?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "params['id']=#{params['id']}",
                                           "params['noid']=#{params['noid']}",
                                           "" ] if aptrust_statuses_controller_debug_verbose
    records = ::Aptrust::Status.where( id: params['id'] )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "records.size=#{records.size}",
                                           "" ] if aptrust_statuses_controller_debug_verbose
    return if records.size < 1 # TODO: error
    record = records[0]
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "record.id=#{record.id}",
                                           "record.noid=#{record.noid}",
                                           "" ] if aptrust_statuses_controller_debug_verbose
    record.event = ::Aptrust::EVENT_UPLOAD_AGAIN
    record.note = ''
    record.timestamp = DateTime.now
    record.save
  end

  def status_failed
    raise CanCan::AccessDenied unless current_ability.admin?
    init_aptrust_statuses( event: 'failed' )
    render 'aptrust/index'
  end

  def status_finished
    raise CanCan::AccessDenied unless current_ability.admin?
    init_aptrust_statuses( event: ::Aptrust::EVENT_FINISHED )
    render 'aptrust/index'
  end

  def status_not_finished
    raise CanCan::AccessDenied unless current_ability.admin?
    init_aptrust_statuses( not_event: ::Aptrust::EVENT_FINISHED )
    render 'aptrust/index'
  end

  def status_started
    raise CanCan::AccessDenied unless current_ability.admin?
    init_aptrust_statuses( event: ::Aptrust::EVENT_STARTED )
    render 'aptrust/index'
  end

  # PATCH/PUT /aptrust_statuses/1 or /aptrust_statuses/1.json
  def update
    raise CanCan::AccessDenied unless current_ability.admin?
    respond_to do |format|
      if @aptrust_status.update(aptrust_status_params)
        format.html { redirect_to @aptrust_status, notice: "Aptrust status was successfully updated." }
        format.json { render :show, event: :ok, location: @aptrust_status }
      else
        format.html { render :edit, event: :unprocessable_entity }
        format.json { render json: @aptrust_status.errors, event: :unprocessable_entity }
      end
    end
  end

end
end
