# frozen_string_literal: true

module AnalyticsHelper

  ANALYTICS_HELPER_DEBUG_VERBOSE = ::Deepblue::AnalyticsIntegrationService.analytics_helper_debug_verbose

  def self.chartkick?
    ::Deepblue::AnalyticsIntegrationService.enable_chartkick
  end

  def self.hit_graph_admin?
    # 0 = none, 1 = admin, 2 = editor, 3 = everyone
    0 < ::Deepblue::AnalyticsIntegrationService.hit_graph_view_level
  end

  def self.hit_graph_editor?
    # 0 = none, 1 = admin, 2 = editor, 3 = everyone
    1 < ::Deepblue::AnalyticsIntegrationService.hit_graph_view_level
  end

  def self.hit_graph_everyone?
    # 0 = none, 1 = admin, 2 = editor, 3 = everyone
    2 < ::Deepblue::AnalyticsIntegrationService.hit_graph_view_level
  end

  def self.page_hits_by_date( controller_class:, cc_id: nil, date_range: nil )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "controller_class.name=#{controller_class.name}",
                                           "cc_id=#{cc_id}",
                                           "date_range=#{date_range}",
                                           "" ] if ANALYTICS_HELPER_DEBUG_VERBOSE

    # TODO: add date_range constraint
    if date_range.blank? && ::Deepblue::AnalyticsIntegrationService.hit_graph_day_window > 0
      date_range = ::Deepblue::AnalyticsIntegrationService.hit_graph_day_window.days.ago..(Date.today + 1.day)
    end
    if cc_id.present?
      if date_range.blank?
        Ahoy::Event.where( name: "#{controller_class.name}#show", cc_id: cc_id ).group_by_day( :time ).count
      else
        sql = Ahoy::Event.where( name: "#{controller_class.name}#show", cc_id: cc_id, time: date_range ).group_by_day( :time ).to_sql
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "sql=#{sql}",
                                               "" ] if ANALYTICS_HELPER_DEBUG_VERBOSE
        Ahoy::Event.where( name: "#{controller_class.name}#show", cc_id: cc_id, time: date_range ).group_by_day( :time ).count
      end
    elsif date_range.present?
      Ahoy::Event.where( name: "#{controller_class.name}#show", date_created: date_range ).group_by_day( :time ).count
    else
      Ahoy::Event.where( name: "#{controller_class.name}#show" ).group_by_day( :time ).count
    end
  end

  def self.show_hit_graph?( current_ability, presenter: nil )
    # 0 = none, 1 = admin, 2 = editor, 3 = everyone
    return false if presenter.respond_to?( :single_use_show? ) && presenter.single_use_show?
    case ::Deepblue::AnalyticsIntegrationService.hit_graph_view_level
    when 0
      false
    when 1
      current_ability.admin?
    when 2
      return presenter.editor? if presenter.respond_to? :editor?
      return current_ability.editor? if current_ability.respond_to? :editor?
      false
    when 3
      true
    else
      false
    end
  end

end
