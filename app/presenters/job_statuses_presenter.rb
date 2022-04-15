# frozen_string_literal: true

class JobStatusesPresenter

  include Deepblue::DeepbluePresenterBehavior

  attr_accessor :controller, :current_ability

  delegate :begin_date, :end_date, to: :controller

  # delegate  :log_entries, :log_parse_entry, :log_key_values_to_table, to: :controller

  def initialize( controller:, current_ability: )
    @controller = controller
    @current_ability = current_ability
  end

  def begin_date_parm
    rv = begin_date
    return '' unless rv.present?
    rv.strftime("%Y-%m-%d")
  end

  def end_date_parm
    rv = end_date
    return '' unless rv.present?
    rv.strftime("%Y-%m-%d")
  end

end