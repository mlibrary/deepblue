# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Deepblue::AnalyticsIntegrationService do

  describe 'constants' do
    it "resolves them" do
      expect( ::Deepblue::AnalyticsIntegrationService.ahoy_tracker_debug_verbose         ).to eq( false )
      expect( ::Deepblue::AnalyticsIntegrationService.analytics_helper_debug_verbose     ).to eq( false )
      expect( ::Deepblue::AnalyticsIntegrationService.enable_chartkick                   ).to eq( true )
      expect( ::Deepblue::AnalyticsIntegrationService.enable_collections_hit_graph       ).to eq( false )
      expect( ::Deepblue::AnalyticsIntegrationService.enable_file_sets_hit_graph         ).to eq( true )
      expect( ::Deepblue::AnalyticsIntegrationService.enable_works_hit_graph             ).to eq( true )
      expect( ::Deepblue::AnalyticsIntegrationService.event_tracking_debug_verbose       ).to eq( false )
      expect( ::Deepblue::AnalyticsIntegrationService.event_tracking_excluded_parameters ).to eq( [:authenticity_token] )
      expect( ::Deepblue::AnalyticsIntegrationService.event_tracking_include_request_uri ).to eq( false )
      expect( ::Deepblue::AnalyticsIntegrationService.hit_graph_day_window               ).to eq( -1 )
      expect( ::Deepblue::AnalyticsIntegrationService.hit_graph_view_level               ).to eq( 1 )
      expect( ::Deepblue::AnalyticsIntegrationService.monthly_events_report_subscription_id ).to eq( 'MonthlyEventsReport' )
    end
  end

end
