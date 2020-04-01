# frozen_string_literal: true

class SchedulerDashboardController < ApplicationController
  include ActiveSupport::Concern
  include Blacklight::Base
  include Blacklight::AccessControls::Catalog
  include Hyrax::Breadcrumbs
  with_themed_layout 'dashboard'
  before_action :authenticate_user!
  before_action :build_breadcrumbs, only: [:show]

  class_attribute :presenter_class
  self.presenter_class = SchedulerDashboardPresenter

  attr_reader :action_error

  def action
    ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "params[:commit]=#{params[:commit]}",
                                           "" ]
    if scheduler_active
      action = params[:commit]
      @action_error = false
      msg = case action
            when MsgHelper.t( 'simple_form.actions.scheduler.restart' )
              action_restart
            when MsgHelper.t( 'simple_form.actions.scheduler.start' )
              action_start
            when MsgHelper.t( 'simple_form.actions.scheduler.stop' )
              action_stop
            else
              @action_error = true
              "Unkown action #{action}"
            end
      if action_error
        redirect_to scheduler_dashboard_path, alert: msg
      else
        redirect_to scheduler_dashboard_path, notice: msg
      end
    else
      msg = "ERROR: #{scheduler_active_status}"
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "msg=#{msg}",
                                             "" ]
      redirect_to scheduler_dashboard_path, alert: msg
    end
  end

  def edit_schedule
    @edit_schedule ||= edit_schedule_load
  end

  def edit_schedule_load
    return "" unless File.exists? ::Deepblue::SchedulerIntegrationService.scheduler_job_file_path
    rv = []
    open( ::Deepblue::SchedulerIntegrationService.scheduler_job_file_path, "r" ) { |f| rv = f.readlines }
    rv.join("")
  end

  def edit_schedule_save
    unless File.exists? ::Deepblue::SchedulerIntegrationService.scheduler_job_file_path
      parentdir = Pathname( ::Deepblue::SchedulerIntegrationService.scheduler_job_file_path ).parent
      FileUtils.mkdir_p(parentdir.to_s) unless parentdir.exist?
    end
    new_schedule = params[:edit_schedule_textarea]
    return if new_schedule.blank?
    open( ::Deepblue::SchedulerIntegrationService.scheduler_job_file_path, "w" ) do |out|
      out.puts new_schedule
    end
  end

  def update_schedule
    edit_schedule_save
    redirect_to scheduler_dashboard_path
  end

  def show
    @presenter = presenter_class.new( controller: self, current_ability: current_ability )
    render 'hyrax/dashboard/show_scheduler_dashboard'
  end

  def scheduler_active
    ::Deepblue::SchedulerIntegrationService.scheduler_active
  end

  def scheduler_active_status
    return MsgHelper.t( 'hyrax.scheduler.can_run', hostname: DeepBlueDocs::Application.config.hostname ) if scheduler_active
    MsgHelper.t( 'hyrax.scheduler.can_not_run_html', hostname: DeepBlueDocs::Application.config.hostname )
  end

  def scheduler_not_active
    !::Deepblue::SchedulerIntegrationService.scheduler_active
  end

  def scheduler_pid
    ::Deepblue::SchedulerIntegrationService.scheduler_pid
  end

  def scheduler_running
    scheduler_pid.present?
  end

  def scheduler_status
    return MsgHelper.t( "hyrax.scheduler.running") if scheduler_running
    MsgHelper.t( 'hyrax.scheduler.not_running_html' )
  end

  protected

    def action_restart
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "" ]
      ::Deepblue::SchedulerIntegrationService.scheduler_restart
    end

    def action_start
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "" ]
      ::Deepblue::SchedulerIntegrationService.scheduler_start
    end

    def action_stop
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "" ]
      ::Deepblue::SchedulerIntegrationService.scheduler_stop
    end

end
