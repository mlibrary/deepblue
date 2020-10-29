# frozen_string_literal: true

module Deepblue

  module AnalyticsIntegrationService

    @@_setup_ran = false
    @@_setup_failed = false

    @@ahoy_tracker_debug_verbose = false
    @@analytics_helper_debug_verbose = false
    @@event_tracking_debug_verbose = false

    @@enable_chartkick = false
    @@enable_collections_hit_graph = false
    @@enable_file_sets_hit_graph = false
    @@enable_works_hit_graph = false
    @@event_tracking_excluded_parameters = []
    @@event_tracking_include_request_uri = false
    @@hit_graph_day_window = 30 # set to < 1 for no limit
    @@hit_graph_view_level = 0 # 0 = none, 1 = admin, 2 = editor, 3 = everyone
    @@monthly_events_report_subscription_id = 'MonthlyEventsReport'

    mattr_accessor :ahoy_tracker_debug_verbose,
                   :analytics_helper_debug_verbose,
                   :enable_chartkick,
                   :enable_collections_hit_graph,
                   :enable_file_sets_hit_graph,
                   :enable_works_hit_graph,
                   :event_tracking_debug_verbose,
                   :event_tracking_excluded_parameters,
                   :event_tracking_include_request_uri,
                   :hit_graph_day_window,
                   :hit_graph_view_level,
                   :monthly_events_report_subscription_id


                   def self.setup
      return if @@_setup_ran == true
      @@_setup_ran = true
      begin
        yield self
      rescue Exception => e # rubocop:disable Lint/RescueException
        @@_setup_failed = true
      end
    end

  end

end
