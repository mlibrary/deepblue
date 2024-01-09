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

  attr_accessor :back_id, :begin_date, :end_date

  attr_reader :action_error

  def action
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "params[:commit]=#{params[:commit]}",
                                           "" ] if aptrust_statuses_controller_debug_verbose
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
      redirect_to aptrust_statuses_path, alert: msg
    else
      redirect_to aptrust_statuses_path, notice: msg
    end
  end

  # POST /aptrust_statuses or /aptrust_statuses.json
  def create
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if aptrust_statuses_controller_debug_verbose
    raise CanCan::AccessDenied unless current_ability.admin?
    @aptrust_status = Aptrust::Status.new(aptrust_status_params)

    respond_to do |format|
      if @aptrust_status.save
        format.html { redirect_to @aptrust_status, notice: "Aptrust status was successfully created." }
        format.json { render :show, event: :created, location: @aptrust_status }
      else
        format.html { render :new, event: :unprocessable_entity }
        format.json { render json: @aptrust_status.errors, event: :unprocessable_entity }
      end
    end
  end

  # DELETE /aptrust_statuses/1 or /aptrust_statuses/1.json
  def destroy
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if aptrust_statuses_controller_debug_verbose
    raise CanCan::AccessDenied unless current_ability.admin?
    @aptrust_status.destroy
    respond_to do |format|
      format.html { redirect_to aptrust_statuses_url, notice: "Aptrust status was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  # GET /aptrust_statuses/1/edit
  def edit
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if aptrust_statuses_controller_debug_verbose
    raise CanCan::AccessDenied unless current_ability.admin?
  end

  def has_error
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if aptrust_statuses_controller_debug_verbose
    raise CanCan::AccessDenied unless current_ability.admin?
    init_aptrust_statuses_errors
    render 'index'
  end

  # GET /aptrust_statuses or /aptrust_statuses.json
  def index
    raise CanCan::AccessDenied unless current_ability.admin?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params[:commit]=#{params[:commit]}",
                                           "" ] if aptrust_statuses_controller_debug_verbose
    case params[:commit]
    when 'All'
      init_aptrust_statuses
    when 'Deposited'
      init_aptrust_statuses( event: ::Aptrust::EVENT_DEPOSITED )
    when 'Exported'
      init_aptrust_statuses( event: ::Aptrust::EVENT_EXPORTED )
    when 'Failed'
      init_aptrust_statuses( event: ::Aptrust::EVENT_FAILED )
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
    else
      init_aptrust_statuses
    end
    @presenter = presenter_class.new( controller: self, current_ability: current_ability )
    render 'aptrust/index'
  end

  def init_begin_end_dates
    @back_id = params[:back_id] # TODO: rename this method
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
                                           "event=#{event}",
                                           "not_event=#{not_event}",
                                           "" ] if aptrust_statuses_controller_debug_verbose
    init_begin_end_dates
    @aptrust_statuses = if event.blank? && not_event.blank?
                      Status.where( [ 'created_at >= ? AND created_at <= ?', begin_date, end_date ] )
                                     .order( created_at: :desc )
                    elsif not_event.blank?
                      Status.where( [ 'created_at >= ? AND created_at <= ?', begin_date, end_date ] )
                                     .where( event: event )
                                     .order( created_at: :desc )
                    elsif event.blank?
                      Status.where( [ 'created_at >= ? AND created_at <= ?', begin_date, end_date ] )
                                     .where.not( event: not_event )
                        .order( created_at: :desc )
                    else
                      Status.where( [ 'created_at >= ? AND created_at <= ?', begin_date, end_date ] )
                                     .where( event: event )
                                     .where.not( event: not_event )
                                     .order( created_at: :desc )
                    end
  end

  # Only allow a list of trusted parameters through.
  def aptrust_status_params
    params.fetch(:aptrust_status, {})
  end

  # TODO: is_recent view

  # GET /aptrust_statuses/new
  def new
    raise CanCan::AccessDenied unless current_ability.admin?
    @aptrust_status = Status.new
  end

  # GET /aptrust_statuses/1 or /aptrust_statuses/1.json
  def show
    raise CanCan::AccessDenied unless current_ability.admin?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "" ] if aptrust_statuses_controller_debug_verbose
    init_begin_end_dates
    @presenter = presenter_class.new( controller: self, current_ability: current_ability )
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
    @aptrust_status = Status.find(params[:id])
  end

  def status_failed
    raise CanCan::AccessDenied unless current_ability.admin?
    init_aptrust_statuses( event: 'failed' )
    render 'index'
  end

  def status_finished
    raise CanCan::AccessDenied unless current_ability.admin?
    init_aptrust_statuses( event: ::Aptrust::EVENT_FINISHED )
    render 'index'
  end

  def status_not_finished
    raise CanCan::AccessDenied unless current_ability.admin?
    init_aptrust_statuses( not_event: ::Aptrust::EVENT_FINISHED )
    render 'index'
  end

  def status_started
    raise CanCan::AccessDenied unless current_ability.admin?
    init_aptrust_statuses( event: ::Aptrust::EVENT_STARTED )
    render 'index'
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
