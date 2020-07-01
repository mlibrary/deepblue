# frozen_string_literal: true

class GoogleAnalyticsDashboardPresenter

  attr_accessor :controller, :current_ability

  def initialize( controller:, current_ability: )
    @controller = controller
    @current_ability = current_ability
  end

end