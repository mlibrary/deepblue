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
    @id_to_total_file_size_map = {}
  end

  def run_button
    I18n.t('simple_form.actions.report.run_report_job')
  end

  def total_size( total_size )
    return 0 if total_size.blank?
    ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert( total_size, precision: 3 )
  end

  def work_total_size( work: nil, id: nil )
    return nil if work.blank? && id.blank?
    return @id_to_total_file_size_map[id] if id.present? && @id_to_total_file_size_map.has_key?( id )
    work ||= PersistHelper.find_solr( id, fail_if_not_found: false )
    total_size = work.total_file_size
    total_size ||= 0
    @id_to_total_file_size_map[id] = total_size
    total_size
  end

end