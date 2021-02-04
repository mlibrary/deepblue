# frozen_string_literal: true

class IngestDashboardPresenter

  include ::Deepblue::DeepbluePresenterBehavior

  delegate :ingest_mode, :paths_to_scripts, to: :controller

  attr_accessor :controller, :current_ability

  def initialize( controller:, current_ability: )
    @controller = controller
    @current_ability = current_ability
  end

  def allowed_path_prefixes
    MultipleIngestScriptsJob.scripts_allowed_path_prefixes
  end

  def ingest_file_paths
    "" # initially none, will want to carry them forward in the future
  end

end