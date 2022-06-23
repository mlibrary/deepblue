# frozen_string_literal: true

class JobStatusesController < ApplicationController

  mattr_accessor :job_statuses_controller_debug_verbose, default: false

  include AdminOnlyControllerBehavior

  with_themed_layout 'dashboard'

  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :set_date_range #, only: %i[ index ]
  before_action :set_job_status, only: %i[ show edit update destroy ]

  class_attribute :presenter_class, default: JobStatusesPresenter

  attr_accessor :back_id, :begin_date, :end_date

  attr_reader :action_error

  def action
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "params[:commit]=#{params[:commit]}",
                                           "" ] if job_statuses_controller_debug_verbose
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
      redirect_to job_statuses_path, alert: msg
    else
      redirect_to job_statuses_path, notice: msg
    end
  end

  # POST /job_statuses or /job_statuses.json
  def create
    raise CanCan::AccessDenied unless current_ability.admin?
    @job_status = JobStatus.new(job_status_params)

    respond_to do |format|
      if @job_status.save
        format.html { redirect_to @job_status, notice: "Job status was successfully created." }
        format.json { render :show, status: :created, location: @job_status }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @job_status.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /job_statuses/1 or /job_statuses/1.json
  def destroy
    raise CanCan::AccessDenied unless current_ability.admin?
    @job_status.destroy
    respond_to do |format|
      format.html { redirect_to job_statuses_url, notice: "Job status was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  # GET /job_statuses/1/edit
  def edit
    raise CanCan::AccessDenied unless current_ability.admin?
  end

  def has_error
    raise CanCan::AccessDenied unless current_ability.admin?
    init_job_statuses_errors
    render 'index'
  end

  # GET /job_statuses or /job_statuses.json
  def index
    raise CanCan::AccessDenied unless current_ability.admin?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params[:commit]=#{params[:commit]}",
                                           "" ] if job_statuses_controller_debug_verbose
    case params[:commit]
    when 'All'
      init_job_statuses
    when 'Failed'
      init_job_statuses( status: 'failed' )
    when 'Finished'
      init_job_statuses( status: JobStatus::FINISHED )
    when 'Has Error'
      init_job_statuses_errors
    when 'Not Finished'
      init_job_statuses( not_status: JobStatus::FINISHED )
    when 'Started'
      init_job_statuses( status: JobStatus::STARTED )
    else
      init_job_statuses
    end
    @presenter = presenter_class.new( controller: self, current_ability: current_ability )
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
                                           "" ] if job_statuses_controller_debug_verbose
  end

  def init_job_statuses( status: nil, not_status: nil )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "status=#{status}",
                                           "not_status=#{not_status}",
                                           "" ] if job_statuses_controller_debug_verbose
    init_begin_end_dates
    @job_statuses = if status.blank? && not_status.blank?
                      JobStatus.where(['created_at >= ? AND created_at <= ?', begin_date, end_date])
                               .order(created_at: :desc)
                    elsif not_status.blank?
                      JobStatus.where(['created_at >= ? AND created_at <= ?', begin_date, end_date])
                               .where(status: status)
                               .order(created_at: :desc)
                    elsif status.blank?
                      JobStatus.where(['created_at >= ? AND created_at <= ?', begin_date, end_date])
                               .where.not(status: not_status)
                               .order(created_at: :desc)
                    else
                      JobStatus.where(['created_at >= ? AND created_at <= ?', begin_date, end_date])
                               .where(status: status)
                               .where.not(status: not_status)
                               .order(created_at: :desc)
                    end
  end

  def init_job_statuses_errors
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "errors=#{errors}",
                                           "" ] if job_statuses_controller_debug_verbose
    init_begin_end_dates
    @job_statuses = JobStatus.where(['created_at >= ? AND created_at <= ?', begin_date, end_date])
                               .where.not( error: [nil, ''] )
                               .order(created_at: :desc)
  end

  # Only allow a list of trusted parameters through.
  def job_status_params
    params.fetch(:job_status, {})
  end

  # TODO: is_recent view

  # GET /job_statuses/new
  def new
    raise CanCan::AccessDenied unless current_ability.admin?
    @job_status = JobStatus.new
  end

  # GET /job_statuses/1 or /job_statuses/1.json
  def show
    raise CanCan::AccessDenied unless current_ability.admin?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "" ] if job_statuses_controller_debug_verbose
    init_begin_end_dates
    @presenter = presenter_class.new( controller: self, current_ability: current_ability )
  end

  def set_date_range
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "params[:begin_date]=#{params[:begin_date]}",
                                           "params[:end_date]=#{params[:end_date]}",
                                           "" ] if job_statuses_controller_debug_verbose
    @begin_date = ViewHelper.to_date(params[:begin_date])
    @begin_date ||= Date.today - 1.week
    @end_date = ViewHelper.to_date(params[:end_date])
    @end_date ||= Date.tomorrow
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@begin_date=#{@begin_date}",
                                           "@end_date=#{@end_date}",
                                           "" ] if job_statuses_controller_debug_verbose
  end

  def set_job_status
    @job_status = JobStatus.find(params[:id])
  end

  def status_failed
    raise CanCan::AccessDenied unless current_ability.admin?
    init_job_statuses( status: 'failed' )
    render 'index'
  end

  def status_finished
    raise CanCan::AccessDenied unless current_ability.admin?
    init_job_statuses( status: JobStatus::FINISHED )
    render 'index'
  end

  def status_not_finished
    raise CanCan::AccessDenied unless current_ability.admin?
    init_job_statuses( not_status: JobStatus::FINISHED )
    render 'index'
  end

  def status_started
    raise CanCan::AccessDenied unless current_ability.admin?
    init_job_statuses( status: JobStatus::STARTED )
    render 'index'
  end

  # PATCH/PUT /job_statuses/1 or /job_statuses/1.json
  def update
    raise CanCan::AccessDenied unless current_ability.admin?
    respond_to do |format|
      if @job_status.update(job_status_params)
        format.html { redirect_to @job_status, notice: "Job status was successfully updated." }
        format.json { render :show, status: :ok, location: @job_status }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @job_status.errors, status: :unprocessable_entity }
      end
    end
  end

end
