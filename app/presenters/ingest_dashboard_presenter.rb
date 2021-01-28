# frozen_string_literal: true

class IngestDashboardPresenter

  include ::Deepblue::DeepbluePresenterBehavior

  delegate :some_method, to: :controller

  attr_accessor :controller, :current_ability

  def initialize( controller:, current_ability: )
    @controller = controller
    @current_ability = current_ability
  end

  def ingest_file_paths
    "" # initially none, will want to carry them forward in the future
  end

end