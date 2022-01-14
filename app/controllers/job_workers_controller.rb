# frozen_string_literal: true

class JobWorkersController < ApplicationController

  mattr_accessor :job_workers_controller_debug_verbose, default: false

  # before_action :set_job_worker, only: %i[ show ]

  attr_reader :action_error

  def action
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "params[:commit]=#{params[:commit]}",
                                           "" ] if job_workers_controller_debug_verbose
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
      redirect_to job_workers_path, alert: msg
    else
      redirect_to job_workers_path, notice: msg
    end
  end

  # GET /job_workers or /job_workers.json
  def index
    raise CanCan::AccessDenied unless current_ability.admin?
    @job_workers = Resque::Worker.all.map(&:job)
  end

  private

  def init_job_workers
    Resque::Worker.all.map(&:job).map { |job| JobWorkerPresenter.new( job: job, controller: self ) }
  end

end
