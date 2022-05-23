# frozen_string_literal: true

class SchedulerDashboardPresenter

  mattr_accessor :scheduler_dashboard_cron_human_readable, default: true
  mattr_accessor :scheduler_dashboard_cron_check_args, default: true

  include Deepblue::DeepbluePresenterBehavior

  delegate :edit_schedule,
           :job_schedule,
           :job_schedule_jobs,
           :scheduler_active,
           :scheduler_active_status,
           :scheduler_not_active,
           :scheduler_subscribe_jobs,
           :scheduler_subscribe_jobs_hash,
           :scheduler_running,
           :scheduler_status, to: :controller

  attr_accessor :controller, :current_ability

  def initialize( controller:, current_ability: )
    @controller = controller
    @current_ability = current_ability
  end

  def cron_entry( job_parameters )
    cron = job_parameters['cron']
    if scheduler_dashboard_cron_check_args && job_parameters['args'].present?
      args = job_parameters['args']
      return 'By Request' if args['by_request_only']
      hostnames = args['hostnames']
      hostnames ||= []
      return 'Disabled' unless hostnames.include? Rails.configuration.hostname
    end
    return cron_human_readable(cron) if scheduler_dashboard_cron_human_readable
    return "<span class=\"monospace-code\">#{cron}</span>"
  end

  def cron_human_readable(cron)
    Cronex::ExpressionDescriptor.new(cron, locale: I18n.locale).description
  end

end
