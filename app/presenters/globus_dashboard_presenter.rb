# frozen_string_literal: true

class GlobusDashboardPresenter

  include ::Deepblue::DeepbluePresenterBehavior

  mattr_accessor :globus_dashboard_presenter_debug_verbose,
                 default: ::Deepblue::GlobusIntegrationService.globus_dashboard_presenter_debug_verbose

  delegate :globus_du_for, to: :controller
  delegate :globus_download_dir_du, to: :controller
  delegate :globus_prep_dir_du, to: :controller
  delegate :globus_prep_tmp_dir_du, to: :controller
  delegate :globus_locked?, to: :controller
  delegate :globus_status, to: :controller

  delegate :globus_always_available?, to: :controller
  delegate :globus_base_url, to: :controller
  delegate :globus_bounce_external_link_off_server?, to: :controller
  delegate :globus_controller_behavior_debug_verbose, to: :controller
  delegate :globus_controller_behavior_presenter_debug_verbose, to: :controller
  delegate :globus_copy_complete?, to: :controller
  delegate :globus_debug_verbose?, to: :controller
  delegate :globus_data_den_files_available?, to: :controller
  delegate :globus_data_den_published_dir, to: :controller
  delegate :globus_download_enabled?, to: :controller
  delegate :globus_enabled?, to: :controller
  delegate :globus_error_file_exists?, to: :controller
  delegate :globus_export?, to: :controller
  delegate :globus_external_url, to: :controller
  delegate :globus_files_available?, to: :controller
  delegate :globus_files_prepping?, to: :controller
  delegate :globus_files_target_file_name, to: :controller
  delegate :globus_last_error_msg, to: :controller
  delegate :globus_use_data_den?, to: :controller

  attr_accessor :controller, :current_ability

  def initialize( controller:, current_ability: )
    @controller = controller
    @current_ability = current_ability
    @id_to_work_map = {}
  end

  def globus_simple_form_link_str
    rv = ::Deepblue::EmailHelper.t('simple_form.hints.data_set.globus_link')
    return rv unless globus_debug_verbose?
    if globus_use_data_den?
      rv += " from DataDen"
    else
      rv += " from Legacy"
    end
    rv
  end

  def run_button
    I18n.t('simple_form.actions.report.run_report_job')
  end

  def work_title( work )
    return work.title_or_label if work.respond_to? :title_or_label
    rv = Array( work.title ).join(', ')
    return rv
  end

  def total_size( work )
    return 0 unless work.present?
    total_size = work.total_file_size
    return 0 if total_size.blank?
    ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert( total_size, precision: 3 )
  end

  def work( id: nil, work: nil )
    return work if work.present?
    return nil if id.blank?
    work = @id_to_work_map[id]
    return work if work.present?
    work = PersistHelper.find_solr( id, fail_if_not_found: false )
    @id_to_work_map[id] = work if work.present?
    return work
  end

end
