# frozen_string_literal: true

class SchedulerDashboardController < ApplicationController

  mattr_accessor :scheduler_dashboard_controller_debug_verbose, default: false

  include ActiveSupport::Concern
  include Blacklight::Base
  include Blacklight::AccessControls::Catalog
  include Hyrax::Breadcrumbs
  include AdminOnlyControllerBehavior

  with_themed_layout 'dashboard'

  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :build_breadcrumbs, only: [:show]

  class_attribute :presenter_class
  self.presenter_class = SchedulerDashboardPresenter

  attr_reader :action_error

  def action
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "params[:commit]=#{params[:commit]}",
                                           "" ] if scheduler_dashboard_controller_debug_verbose
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
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "msg=#{msg}",
                                             "" ] if scheduler_dashboard_controller_debug_verbose
      redirect_to scheduler_dashboard_path, alert: msg
    end
  end

  def edit_schedule
    @edit_schedule ||= edit_schedule_load
  end

  def edit_schedule_load
    return "" unless File.exists? ::Deepblue::SchedulerIntegrationService.scheduler_job_file_path
    rv = []
    File.open( ::Deepblue::SchedulerIntegrationService.scheduler_job_file_path, "r" ) { |f| rv = f.readlines }
    rv.join("")
  end

  def edit_schedule_save
    unless File.exists? ::Deepblue::SchedulerIntegrationService.scheduler_job_file_path
      parentdir = Pathname( ::Deepblue::SchedulerIntegrationService.scheduler_job_file_path ).parent
      FileUtils.mkdir_p(parentdir.to_s) unless parentdir.exist?
    end
    new_schedule = params[:edit_schedule_textarea]
    return if new_schedule.blank?
    File.open( ::Deepblue::SchedulerIntegrationService.scheduler_job_file_path, "w" ) do |out|
      out.puts new_schedule
    end
  end

  def job_action
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "params[:commit]=#{params[:commit]}",
                                           "params[:job_name]=#{params[:job_name]}",
                                           "" ] if scheduler_dashboard_controller_debug_verbose
    action = params[:commit]
    job_name = params[:job_name]
    @action_error = false
    msg = case action
          when MsgHelper.t('hyrax.scheduler.submit.run')
            job_action_run( job_name: job_name )
          when MsgHelper.t('hyrax.scheduler.submit.subscribe')
            job_action_subscribe( job_name: job_name )
          when MsgHelper.t('hyrax.scheduler.submit.unsubscribe')
            job_action_unsubscribe( job_name: job_name )
          else
            @action_error = true
            "Unkown action #{action}"
          end
    if action_error
      redirect_to scheduler_dashboard_path, alert: msg
    else
      redirect_to scheduler_dashboard_path, notice: msg
    end
  rescue Exception => e
    msg = "ERROR: #{e}"
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "msg=#{msg}",
                                           "" ] if scheduler_dashboard_controller_debug_verbose
    redirect_to scheduler_dashboard_path, alert: msg + e.backtrace[0..5].join("\n")
  end

  def job_action_run( job_name: )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "job_name=#{job_name}",
                                           "" ] if scheduler_dashboard_controller_debug_verbose
    job_entry = job_schedule[job_name]
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "job_entry=#{job_entry}",
                                           "" ] if scheduler_dashboard_controller_debug_verbose
    if job_entry.blank?
      msg = "Job #{job} not found."
      return redirect_to scheduler_dashboard_path, alert: msg
    end
    job_class_name = job_entry['class']
    args = job_entry['args']
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "job_class_name=#{job_class_name}",
                                           "args=#{args}",
                                           "" ] if scheduler_dashboard_controller_debug_verbose
    # Add this hostname to hostnames if it exists
    args['hostnames'] << Rails.configuration.hostname if args.has_key? 'hostnames'
    # Ensure that job isn't 'quiet', i.e. send always send results
    args['quiet'] = false if args.has_key? 'quiet'
    args['from_dashboard'] = current_user.email
    job_class = job_class_name.constantize
    job_class.set( queue: :default ).perform_later( *args ) if Rails.env.production?
    job_class.perform_now( args ) if Rails.env.development?
    return "Start #{job_name} to run in the background."
  end

  def job_action_subscribe( job_name: )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "job_name=#{job_name}",
                                           "" ] if scheduler_dashboard_controller_debug_verbose
    subscription_service_id = subscription_service_id( job_name: job_name )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "subscription_service_id=#{subscription_service_id}",
                                           "" ] if scheduler_dashboard_controller_debug_verbose
    if subscription_service_id.blank?
      @action_error = true
      return "'#{job_name}' subscription id not found."
    end
    scheduler_job_subscribe( subscription_service_id: subscription_service_id )
    return "#Subscribed to '#{subscription_service_id}'"
  end

  def job_action_unsubscribe( job_name: )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "job_name=#{job_name}",
                                           "" ] if scheduler_dashboard_controller_debug_verbose
    subscription_service_id = subscription_service_id( job_name: job_name )
    if subscription_service_id.blank?
      @action_error = true
      return "'#{job_name}' subscription id not found."
    end
    scheduler_job_unsubscribe( subscription_service_id: subscription_service_id )
    return "#Unsubscribed from '#{subscription_service_id}'"
  end

  def job_schedule
    @job_schedule ||= job_schedule_init
  end

  def job_schedule_init
    schedule_file = ::Deepblue::SchedulerIntegrationService.scheduler_job_file_path.to_s
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "schedule_file=#{schedule_file}",
                                           "" ] if scheduler_dashboard_controller_debug_verbose
    return {} unless File.exist? schedule_file
    YAML.load_file( schedule_file )
  end

  def job_schedule_jobs
    @job_schedule_jobs ||= job_schedule_jobs_init
  end

  def job_schedule_job_args( job_name: )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "job_name=#{job_name}",
                                           "" ] if scheduler_dashboard_controller_debug_verbose
    schedule_entry = job_schedule[job_name]
    return {} if schedule_entry.nil?
    args = schedule_entry['args']
    return args
  end

  def job_schedule_jobs_init
    job_schedule.keys
  end

  def scheduler_active
    ::Deepblue::SchedulerIntegrationService.scheduler_active
  end

  def scheduler_active_status
    return MsgHelper.t( 'hyrax.scheduler.can_run', hostname: Rails.configuration.hostname ) if scheduler_active
    MsgHelper.t( 'hyrax.scheduler.can_not_run_html', hostname: Rails.configuration.hostname )
  end

  def scheduler_job_subscribe( subscription_service_id: )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "subscription_service_id=#{subscription_service_id}",
                                           "current_ability.current_user=#{current_ability.current_user}",
                                           "" ] if scheduler_dashboard_controller_debug_verbose
    record = EmailSubscription.find_or_create_by( subscription_name: subscription_service_id,
                                                  user_id: current_ability.current_user.id )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "record=#{record}",
                                           "" ] if scheduler_dashboard_controller_debug_verbose
    record.email = current_user.email
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "record=#{record}",
                                           "" ] if scheduler_dashboard_controller_debug_verbose
    record.save
  end

  def scheduler_job_unsubscribe( subscription_service_id: )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "subscription_service_id=#{subscription_service_id}",
                                           "current_ability.current_user=#{current_ability.current_user}",
                                           "" ] if scheduler_dashboard_controller_debug_verbose
    record = EmailSubscription.where( subscription_name: subscription_service_id,
                                      user_id: current_ability.current_user.id ).limit( 1 )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "record=#{record}",
                                           "" ] if scheduler_dashboard_controller_debug_verbose
    return if record.blank?
    record = record.first
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "record=#{record}",
                                           "" ] if scheduler_dashboard_controller_debug_verbose
    record.destroy if record.present?
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

  def scheduler_subscribed_to_job( subscription_service_id:, current_user: )
    0 < EmailSubscription.where( subscription_name: subscription_service_id, user_id: current_user.id ).count
  end

  def subscription_service_id( job_name: )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "job_name=#{job_name}",
                                           "" ] if scheduler_dashboard_controller_debug_verbose
    args = job_schedule_job_args( job_name: job_name )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "args=#{args}",
                                           "" ] if scheduler_dashboard_controller_debug_verbose
    return nil if args.blank?
    rv = args['subscription_service_id']
    return rv
  end

  def scheduler_subscribe_jobs
    current_user = current_ability.current_user
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "::Deepblue::SchedulerIntegrationService.scheduler_job_file_path.to_s=#{::Deepblue::SchedulerIntegrationService.scheduler_job_file_path.to_s}",
                                           "" ] if scheduler_dashboard_controller_debug_verbose
    subscription_service_ids = []
    job_schedule.each do |job_name,job_parameters|
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "job_name=#{job_name}",
                                             "" ] if scheduler_dashboard_controller_debug_verbose
      args = job_parameters['args']
      if args.present? && args['subscription_service_id'].present?
        subscription_service_id = args['subscription_service_id']
        subscribed = scheduler_subscribed_to_job( subscription_service_id: subscription_service_id,
                                                  current_user: current_user )
        subscription_service_ids << [ subscription_service_id, subscribed ]
      end
    end
    return subscription_service_ids
  end

  def scheduler_subscribe_jobs_hash
    @scheduler_subscribe_jobs_hash ||= scheduler_subscribe_jobs_hash_init
  end

  def scheduler_subscribe_jobs_hash_init
    current_user = current_ability.current_user
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "::Deepblue::SchedulerIntegrationService.scheduler_job_file_path.to_s=#{::Deepblue::SchedulerIntegrationService.scheduler_job_file_path.to_s}",
                                           "" ] if scheduler_dashboard_controller_debug_verbose
    hash = {}
    job_schedule.each do |job_name,job_parameters|
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "job_name=#{job_name}",
                                             "" ] if scheduler_dashboard_controller_debug_verbose
      args = job_parameters['args']
      if args.present? && args['subscription_service_id'].present?
        subscription_service_id = args['subscription_service_id']
        subscribed = scheduler_subscribed_to_job( subscription_service_id: subscription_service_id,
                                                  current_user: current_user )
        hash[subscription_service_id] = subscribed
      end
    end
    return hash
  end

  def show
    @presenter = presenter_class.new( controller: self, current_ability: current_ability )
    render 'hyrax/dashboard/show_scheduler_dashboard'
  end

  def update_schedule
    edit_schedule_save
    redirect_to scheduler_dashboard_path
  end

  protected

    def action_restart
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if scheduler_dashboard_controller_debug_verbose
      ::Deepblue::SchedulerIntegrationService.scheduler_restart( user: current_user,
                                                                 debug_verbose: scheduler_dashboard_controller_debug_verbose )
    end

    def action_start
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if scheduler_dashboard_controller_debug_verbose
      ::Deepblue::SchedulerIntegrationService.scheduler_start( user: current_user,
                                                               debug_verbose: scheduler_dashboard_controller_debug_verbose )
    end

    def action_stop
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if scheduler_dashboard_controller_debug_verbose
      ::Deepblue::SchedulerIntegrationService.scheduler_stop( debug_verbose: scheduler_dashboard_controller_debug_verbose )
    end

end
