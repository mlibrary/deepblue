# frozen_string_literal: true

module Aptrust
  class AptrustEventsPresenter

    include ::Deepblue::DeepbluePresenterBehavior

    attr_accessor :controller, :current_ability

    delegate :begin_date, :end_date, to: :controller

    delegate  :status_id, :aptrust_events, :aptrust_statuses, to: :controller

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
end
