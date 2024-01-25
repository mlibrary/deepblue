# frozen_string_literal: true

require_relative '../../services/aptrust/aptrust'

module Aptrust
class AptrustEventsController < ApplicationController

  mattr_accessor :aptrust_events_controller_debug_verbose, default: false

  include AdminOnlyControllerBehavior

  with_themed_layout 'dashboard'

  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :set_date_range #, only: %i[ index ]
  before_action :set_aptrust_event, only: %i[ show edit update destroy ]

  class_attribute :presenter_class, default: ::Aptrust::AptrustEventsPresenter

  attr_accessor :begin_date, :end_date
  attr_accessor :noid, :status_id
  attr_accessor :aptrust_events
  attr_accessor :aptrust_statuses

  attr_reader :action_error

  def action
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "params[:commit]=#{params[:commit]}",
                                           "" ] if aptrust_events_controller_debug_verbose
    action = params[:commit]
    @action_error = false
    msg = case action
          when MsgHelper.t( 'simple_form.actions.scheduler.restart' )
            action_restart
          else
            @action_error = true
            "Unkown action #{action}"
          end
    if action_error
      redirect_to aptrust_events_path, alert: msg
    else
      redirect_to aptrust_events_path, notice: msg
    end
  end

  def has_error
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if aptrust_events_controller_debug_verbose
    raise CanCan::AccessDenied unless current_ability.admin?
    init_aptrust_events_errors
    render 'aptrust/events/index'
  end

  # GET /aptrust_events or /aptrust_events.json
  def index
    raise CanCan::AccessDenied unless current_ability.admin?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params[:status_id]=#{params[:status_id]}",
                                           "params[:commit]=#{params[:commit]}",
                                           "" ] if aptrust_events_controller_debug_verbose
    @aptrust_events = []
    @aptrust_statuses = []
    if params[:status_id].present?
      init_aptrust_status
    elsif params[:commit].present?
      index_with_commit( commit: params[:commit] )
    else
      init_aptrust_events
    end
    @presenter = presenter_class.new( controller: self, current_ability: current_ability )
    render 'aptrust/events/index'
  end

  def index_with_commit( commit: )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "commit=#{commit}",
                                           "" ] if aptrust_events_controller_debug_verbose
    case commit
    when 'All'
      init_aptrust_events
    when 'Deposited'
      init_aptrust_events( event: ::Aptrust::EVENT_DEPOSITED )
    when 'Exported'
      init_aptrust_events( event: ::Aptrust::EVENT_EXPORTED )
    when 'Failed'
      init_aptrust_events( event: ::Aptrust::EVENTS_FAILED )
    when 'Finished'
      init_aptrust_events( event: ::Aptrust::EVENTS_FINISHED )
    when 'Has Error'
      init_aptrust_events( event: ::Aptrust::EVENTS_ERRORS )
    when 'Not Finished'
      init_aptrust_events( not_event: ::Aptrust::EVENT_EXPORTED )
    when 'Skipped'
      init_aptrust_events( event: ::Aptrust::EVENTS_SKIPPED )
      # init_aptrust_events( event: ::Aptrust::EVENT_UPLOAD_SKIPPED )
    when 'Started'
      init_aptrust_events( event: ::Aptrust::EVENTS_PROCESSING )
    else
      init_aptrust_events
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
                                           "" ] if aptrust_events_controller_debug_verbose
  end

  def init_aptrust_events( event: nil, not_event: nil )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           # "params=#{params}",
                                           "event=#{event}",
                                           "not_event=#{not_event}",
                                           "" ] if aptrust_events_controller_debug_verbose
    init_begin_end_dates
    @aptrust_events = if event.blank? && not_event.blank?
                        Event.where( [ 'created_at >= ? AND created_at <= ?', begin_date, end_date ] )
                             .order( created_at: :desc )
                      elsif not_event.blank?
                        Event.where( [ 'created_at >= ? AND created_at <= ?', begin_date, end_date ] )
                             .where( event: event )
                             .order( created_at: :desc )
                      elsif event.blank?
                        Event.where( [ 'created_at >= ? AND created_at <= ?', begin_date, end_date ] )
                             .where.not( event: not_event )
                             .order( created_at: :desc )
                      else
                        Event.where( [ 'created_at >= ? AND created_at <= ?', begin_date, end_date ] )
                             .where( event: event )
                             .where.not( event: not_event )
                             .order( created_at: :desc )
                      end
  end

  def init_aptrust_status
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if aptrust_events_controller_debug_verbose
    init_status_id
    @aptrust_statuses = Status.where( id: @status_id )
    @aptrust_events = Event.where( aptrust_status_id: @status_id ).order( created_at: :desc )
  end

  def init_status_id()
    @status_id = params[:status_id]
  end

  # Only allow a list of trusted parameters through.
  def aptrust_event_params
    params.fetch(:aptrust_event, {})
  end

  # GET /aptrust_events/1 or /aptrust_events/1.json
  def show
    raise CanCan::AccessDenied unless current_ability.admin?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "" ] if aptrust_events_controller_debug_verbose
    init_begin_end_dates
    @presenter = presenter_class.new( controller: self, current_ability: current_ability )
  end

  def set_date_range
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "params[:begin_date]=#{params[:begin_date]}",
                                           "params[:end_date]=#{params[:end_date]}",
                                           "" ] if aptrust_events_controller_debug_verbose
    @begin_date = ViewHelper.to_date(params[:begin_date])
    @begin_date ||= Date.today - 1.week
    @end_date = ViewHelper.to_date(params[:end_date])
    @end_date ||= Date.tomorrow
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@begin_date=#{@begin_date}",
                                           "@end_date=#{@end_date}",
                                           "" ] if aptrust_events_controller_debug_verbose
  end

  def set_aptrust_event
    @aptrust_event = Event.find(params[:id])
  end

  def event_failed
    raise CanCan::AccessDenied unless current_ability.admin?
    init_aptrust_events( event: 'failed' )
    render 'aptrust/events/index'
  end

  def event_finished
    raise CanCan::AccessDenied unless current_ability.admin?
    init_aptrust_events( event: ::Aptrust::EVENT_FINISHED )
    render 'aptrust/events/index'
  end

  def event_not_finished
    raise CanCan::AccessDenied unless current_ability.admin?
    init_aptrust_events( not_event: ::Aptrust::EVENT_FINISHED )
    render 'aptrust/events/index'
  end

  def event_started
    raise CanCan::AccessDenied unless current_ability.admin?
    init_aptrust_events( event: ::Aptrust::EVENT_STARTED )
    render 'aptrust/events/index'
  end

  # PATCH/PUT /aptrust_events/1 or /aptrust_events/1.json
  def update
    raise CanCan::AccessDenied unless current_ability.admin?
    respond_to do |format|
      if @aptrust_event.update(aptrust_event_params)
        format.html { redirect_to @aptrust_event, notice: "Aptrust event was successfully updated." }
        format.json { render :show, event: :ok, location: @aptrust_event }
      else
        format.html { render :edit, event: :unprocessable_entity }
        format.json { render json: @aptrust_event.errors, event: :unprocessable_entity }
      end
    end
  end

end
end
