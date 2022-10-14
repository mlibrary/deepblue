# frozen_string_literal: true

class GlobusDashboardPresenter

  include ::Deepblue::DeepbluePresenterBehavior

  delegate :globus_status, to: :controller
  # delegate :report_file_path, to: :controller

  attr_accessor :controller, :current_ability

  def initialize( controller:, current_ability: )
    @controller = controller
    @current_ability = current_ability
  end

  def run_button
    I18n.t('simple_form.actions.report.run_report_job')
  end

end