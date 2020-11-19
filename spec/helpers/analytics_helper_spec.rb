# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AnalyticsHelper, type: :helper do

  let(:user) { build(:user) }
  let(:another_user) { build(:user) }
  # let( :flipflop ) { class_double( "Flipflop" ) }

  describe 'constants' do
    it "resolves them" do
      expect( AnalyticsHelper::MONTHLY_EVENTS_REPORT_EVENT_NAME_TO_LABEL_MAP ).to eq(
                                      { "Hyrax::DataSetsController#show" => "Visits",
                                        "Hyrax::DataSetsController#zip_download" => "Zip Downloads",
                                        "Hyrax::DataSetsController#globus_download_redirect" => "Globus Downloads" } )
    end
  end

  describe '.chartkick?' do

    context "is false when Flipflop.enable_local_analytics_ui? is false" do
      before do
        allow( AnalyticsHelper ).to receive( :enable_local_analytics_ui? ).and_return false
      end
      subject { AnalyticsHelper.chartkick? }
      it { expect( subject ).to eq false }
    end

    context "Flipflop.enable_local_analytics_ui? is true" do
      before do
        allow( AnalyticsHelper ).to receive( :enable_local_analytics_ui? ).and_return true
      end
      subject { AnalyticsHelper.chartkick? }
      it { expect( subject ).to eq ::Deepblue::AnalyticsIntegrationService.enable_chartkick }
    end

  end

  # describe '.enable_local_analytics_ui?' do
  ### Can't make the Flipflop test! mechanism work
  ### Can't make allow( Flipflop ).to receive( :enable_local_analytics_ui? ) work
  #   context "is false when Flipflop.enable_local_analytics_ui? is false" do
  #     before do
  #       allow( Flipflop ).to receive( :enable_local_analytics_ui? ).and_return false
  #     end
  #     subject { AnalyticsHelper.enable_local_analytics_ui? }
  #     it { expect( subject ).to eq false }
  #   end
  #
  #   context "is true when Flipflop.enable_local_analytics_ui? is true" do
  #     before do
  #       allow( Flipflop ).to receive( :enable_local_analytics_ui? ).and_return true
  #     end
  #     subject { AnalyticsHelper.enable_local_analytics_ui? }
  #     it { expect( subject ).to eq true }
  #   end
  #
  # end

  describe '.date_range_for_month_of' do
    let( :time ) { Time.new( 2019, 5, 6, 1, 2, 3 ) }
    let( :month_begin ) { Time.new( 2019, 5, 1, 0, 0, 0 ).beginning_of_day }
    let( :month_end ) { Time.new( 2019, 5, 31, 23, 59, 59 ).end_of_day }
    subject { AnalyticsHelper.date_range_for_month_of( time: time ) }
    it { expect( subject ).to eq( month_begin..month_end ) }
  end

  describe '.date_range_for_month_previous' do
    let( :time ) { Time.now - 1.month } # different time diff as starting point than #date_range_for_month_previous
    let( :month_begin ) { time.beginning_of_month }
    let( :month_end ) { time.end_of_month.end_of_day }
    subject { AnalyticsHelper.date_range_for_month_previous }
    it { expect( subject ).to eq( month_begin..month_end ) }
  end

  describe '.email_to_user_id' do
    subject { AnalyticsHelper.email_to_user_id( user.email ) }
    it { expect( subject ).to eq( user.id ) }
  end

  describe '.events_by_date' do
    let( :name ) { "event_name" }
    let( :cc_id ) { "123456789" }
    let( :data_name ) { 'Data Name' }
    let( :today_begin ) { Time.now.beginning_of_day }
    let( :today_end ) { Time.now.end_of_day }
    let( :date_range ) { today_begin..today_end }

    context "no data, no data_name" do
      subject { AnalyticsHelper.events_by_date( name: name, cc_id: cc_id, date_range: date_range ) }
      it { expect( subject ).to eq( {} ) }
    end

    context "no data, with data_name" do
      subject { AnalyticsHelper.events_by_date( name: name, cc_id: cc_id, date_range: date_range, data_name: data_name ) }
      it { expect( subject ).to eq(  { name: 'Data Name', data: {} } ) }
    end

  end

  describe '.show_hit_graph?' do
    let( :analytics_integration_service ) { class_double( Deepblue::AnalyticsIntegrationService ) }
    let( :user ) { FactoryBot.create(:admin) }
    let( :ability ) { Ability.new user }

    context "is false when Flipflop.enable_local_analytics_ui? is false" do
      before do
        allow( AnalyticsHelper ).to receive( :enable_local_analytics_ui? ).and_return false
      end
      subject { AnalyticsHelper.show_hit_graph?( ability ) }
      it { expect( subject ).to eq false }
    end

    context "Flipflop.enable_local_analytics_ui? is true" do
      before do
        allow( analytics_integration_service ).to receive( :hit_graph_view_level ).and_return 1
        allow( AnalyticsHelper ).to receive( :enable_local_analytics_ui? ).and_return true
        allow( ability ).to receive( :admin? ).and_return true
      end
      subject { AnalyticsHelper.show_hit_graph?( ability ) }
      it { expect( subject ).to eq true }
    end

  end

end