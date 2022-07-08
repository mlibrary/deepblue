# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Deepblue::AnalyticsIntegrationService do

  describe 'constants' do
    it { expect( ::Deepblue::AnalyticsIntegrationService.ahoy_tracker_debug_verbose         ).to eq( false ) }
    it { expect( ::Deepblue::AnalyticsIntegrationService.analytics_helper_debug_verbose     ).to eq( false ) }
    it { expect( ::Deepblue::AnalyticsIntegrationService.enable_chartkick                   ).to eq( true ) }
    it { expect( ::Deepblue::AnalyticsIntegrationService.enable_collections_hit_graph       ).to eq( false ) }
    it { expect( ::Deepblue::AnalyticsIntegrationService.enable_file_sets_hit_graph         ).to eq( true ) }
    it { expect( ::Deepblue::AnalyticsIntegrationService.enable_works_hit_graph             ).to eq( true ) }
    it { expect( ::Deepblue::AnalyticsIntegrationService.event_tracking_debug_verbose       ).to eq( false ) }
    it { expect( ::Deepblue::AnalyticsIntegrationService.event_tracking_excluded_parameters ).to eq( [:authenticity_token] ) }
    it { expect( ::Deepblue::AnalyticsIntegrationService.event_tracking_include_request_uri ).to eq( false ) }
    it { expect( ::Deepblue::AnalyticsIntegrationService.hit_graph_day_window               ).to eq( 30 ) }
    it { expect( ::Deepblue::AnalyticsIntegrationService.hit_graph_view_level               ).to eq( 2 ) }
    it { expect( ::Deepblue::AnalyticsIntegrationService.max_visit_filter_count             ).to eq( 50 ) }
    it { expect( ::Deepblue::AnalyticsIntegrationService.skip_admin_events                  ).to eq( true ) }
    it { expect( ::Deepblue::AnalyticsIntegrationService.store_zero_total_downloads         ).to eq( false ) }
    it { expect( ::Deepblue::AnalyticsIntegrationService.monthly_analytics_report_subscription_id ).to eq( 'MonthlyAnalyticsReport' ) }
    it { expect( ::Deepblue::AnalyticsIntegrationService.monthly_events_report_subscription_id ).to eq( 'MonthlyEventsReport' ) }
  end

end
