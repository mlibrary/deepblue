# frozen_string_literal: true

module Deepblue

  module AnalyticsIntegrationService

    @@_setup_ran = false
    @@_setup_failed = false

    def self.setup
      yield self unless @@_setup_ran
      @@_setup_ran = true
    rescue Exception => e # rubocop:disable Lint/RescueException
      @@_setup_failed = true
      msg = "#{e.class}: #{e.message} at #{e.backtrace.join("\n")}"
      # rubocop:disable Rails/Output
      puts msg
      # rubocop:enable Rails/Output
      Rails.logger.error msg
      raise e
    end

    mattr_accessor :ahoy_tracker_debug_verbose, default: false
    mattr_accessor :analytics_helper_debug_verbose, default: false
    mattr_accessor :event_tracking_debug_verbose, default: false

    mattr_accessor :analytics_reports_admins_can_subscribe, default: true
    mattr_accessor :enable_analytics_works_reports_can_subscribe, default: true
    mattr_accessor :enable_chartkick, default: false
    mattr_accessor :enable_collections_hit_graph, default: false
    mattr_accessor :enable_file_sets_hit_graph, default: false
    mattr_accessor :enable_works_hit_graph, default: false
    mattr_accessor :event_tracking_excluded_parameters, default: []
    mattr_accessor :event_tracking_include_request_uri, default: false
    mattr_accessor :hit_graph_day_window, default: 30 # set to < 1 for no limit
    mattr_accessor :hit_graph_view_level, default: 0 # 0 = none, 1 = admin, 2 = editor, 3 = everyone
    mattr_accessor :max_visit_filter_count, default: 50
    mattr_accessor :skip_admin_events, default: true
    mattr_accessor :monthly_analytics_report_subscription_id, default: 'MonthlyAnalyticsReport'
    mattr_accessor :monthly_events_report_subscription_id, default: 'MonthlyEventsReport'

  end

end
