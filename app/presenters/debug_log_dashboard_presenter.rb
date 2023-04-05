# frozen_string_literal: true

class DebugLogDashboardPresenter

  include Deepblue::DeepbluePresenterBehavior

  attr_accessor :controller, :current_ability

  delegate :begin_date, :end_date, to: :controller

  delegate  :log_entries, :log_parse_entry, :log_key_values_to_table, to: :controller

  def initialize( controller:, current_ability: )
    @controller = controller
    @current_ability = current_ability
  end

end