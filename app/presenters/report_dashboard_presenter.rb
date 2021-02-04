# frozen_string_literal: true

class ReportDashboardPresenter

  include ::Deepblue::DeepbluePresenterBehavior

  delegate :edit_report_textarea, to: :controller
  # delegate :report_file_path, to: :controller

  attr_accessor :controller, :current_ability

  def report_file_path
    controller.report_file_path
  end

  def initialize( controller:, current_ability: )
    @controller = controller
    @current_ability = current_ability
  end

  def report_allowed_path_prefixes
    ReportTaskJob.report_task_allowed_path_prefixes
  end

  def run_button
    I18n.t('simple_form.actions.report.run_report_job')
  end

end