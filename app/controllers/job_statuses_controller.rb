# frozen_string_literal: true

class JobStatusesController < ApplicationController

  mattr_accessor :job_statuses_controller_debug_verbose, default: false

  include AdminOnlyControllerBehavior

  with_themed_layout 'dashboard'

  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :set_date_range, only: %i[ index ]
  before_action :set_job_status, only: %i[ show edit update destroy ]

  class_attribute :presenter_class, default: JobStatusesPresenter

  attr_accessor :begin_date, :end_date

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

  # GET /job_statuses or /job_statuses.json
  def index
    raise CanCan::AccessDenied unless current_ability.admin?
    # @job_status = JobStatus.find params[:id]
    @presenter = presenter_class.new( controller: self, current_ability: current_ability )
    @job_statuses = JobStatus.all
  end

  def has_error
    raise CanCan::AccessDenied unless current_ability.admin?
    @job_statuses = JobStatus.where.not( error: [nil, ''] )
    render 'index'
  end

  # TODO: is_recent view

  def status_failed
    raise CanCan::AccessDenied unless current_ability.admin?
    @job_statuses = JobStatus.where( status: 'failed' )
    render 'index'
  end

  def status_not_finished
    raise CanCan::AccessDenied unless current_ability.admin?
    @job_statuses = JobStatus.where.not( status: JobStatus::FINISHED )
    render 'index'
  end

  def status_finished
    raise CanCan::AccessDenied unless current_ability.admin?
    @job_statuses = JobStatus.where( status: JobStatus::FINISHED )
    render 'index'
  end

  def status_started
    raise CanCan::AccessDenied unless current_ability.admin?
    @job_statuses = JobStatus.where( status: JobStatus::STARTED )
    render 'index'
  end

  # GET /job_statuses/1 or /job_statuses/1.json
  def show
    raise CanCan::AccessDenied unless current_ability.admin?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "" ] if job_statuses_controller_debug_verbose
  end

  # GET /job_statuses/new
  def new
    raise CanCan::AccessDenied unless current_ability.admin?
    @job_status = JobStatus.new
  end

  # GET /job_statuses/1/edit
  def edit
    raise CanCan::AccessDenied unless current_ability.admin?
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

  # DELETE /job_statuses/1 or /job_statuses/1.json
  def destroy
    raise CanCan::AccessDenied unless current_ability.admin?
    @job_status.destroy
    respond_to do |format|
      format.html { redirect_to job_statuses_url, notice: "Job status was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  # private

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

  # Only allow a list of trusted parameters through.
  def job_status_params
    params.fetch(:job_status, {})
  end

end
