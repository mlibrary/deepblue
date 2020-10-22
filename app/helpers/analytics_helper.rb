# frozen_string_literal: true

module AnalyticsHelper

  ANALYTICS_HELPER_DEBUG_VERBOSE = true

  def self.page_hits_by_date( controller_class:, cc_id: nil, date_range: nil )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "controller_class.name=#{controller_class.name}",
                                           "cc_id=#{cc_id}",
                                           "date_range=#{date_range}",
                                           "" ] if ANALYTICS_HELPER_DEBUG_VERBOSE

    # TODO: add date_range constraint
    if cc_id.present?
      Ahoy::Event.where( name: "#{controller_class.name}#show", cc_id: cc_id ).group_by_day( :time ).count
    else
      Ahoy::Event.where( name: "#{controller_class.name}#show" ).group_by_day( :time ).count
    end
  end

end
