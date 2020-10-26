# frozen_string_literal: true

class SchedulerDashboardPresenter

  include Deepblue::DeepbluePresenterBehavior

  delegate :edit_schedule,
           :job_schedule_jobs,
           :scheduler_active,
           :scheduler_active_status,
           :scheduler_not_active,
           :scheduler_subscribe_jobs,
           :scheduler_running,
           :scheduler_status, to: :controller

  attr_accessor :controller, :current_ability

  def initialize( controller:, current_ability: )
    @controller = controller
    @current_ability = current_ability
  end

end