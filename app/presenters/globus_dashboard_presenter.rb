# frozen_string_literal: true

class GlobusDashboardPresenter

  include ::Deepblue::DeepbluePresenterBehavior

  delegate :globus_status, to: :controller

  delegate :globus_download_enabled?, to: :controller
  delegate :globus_du_for, to: :controller
  delegate :globus_enabled?, to: :controller
  delegate :globus_error_file_exists?, to: :controller
  delegate :globus_external_url, to: :controller
  delegate :globus_files_available?, to: :controller
  delegate :globus_files_prepping?, to: :controller
  delegate :globus_last_error_msg, to: :controller
  delegate :globus_locked?, to: :controller

  attr_accessor :controller, :current_ability

  def initialize( controller:, current_ability: )
    @controller = controller
    @current_ability = current_ability
  end

  def run_button
    I18n.t('simple_form.actions.report.run_report_job')
  end

end