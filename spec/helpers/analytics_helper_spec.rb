# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AnalyticsHelper, type: :helper do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.analytics_helper_debug_verbose ).to eq debug_verbose }
  end

  describe 'other module values' do
    it { expect( described_class.max_visit_filter_count ).to eq 50 }
    it { expect( described_class.max_visits_per_month_filter ).to eq 100 }
    it { expect( described_class.skip_admin_events ).to eq true }
    it { expect( described_class.store_zero_total_downloads ).to eq false }
  end

  let(:user) { build(:user) }
  let(:another_user) { build(:user) }
  # let( :flipflop ) { class_double( "Flipflop" ) }

  describe 'constants' do
    it { expect( AnalyticsHelper::BEGINNING_OF_TIME ).to eq Time.utc(1972,1,1) }
    it { expect( AnalyticsHelper::END_OF_TIME  ).to eq AnalyticsHelper::BEGINNING_OF_TIME + 1000.year }

    it { expect( AnalyticsHelper::FILE_SET_DWNLDS_PER_MONTH ).to eq "FileSetDownloadsPerMonth" }
    it { expect( AnalyticsHelper::FILE_SET_DWNLDS_TO_DATE ).to eq "FileSetDownloadsToDate" }

    it { expect( AnalyticsHelper::WORK_FILE_DWNLDS_PER_MONTH ).to eq "WorkFileDownloadsPerMonth" }
    it { expect( AnalyticsHelper::WORK_FILE_DWNLDS_TO_DATE ).to eq "WorkFileDownloadsToDate" }
    it { expect( AnalyticsHelper::WORK_GLOBUS_DWNLDS_PER_MONTH ).to eq "WorkGlobusDownloadsPerMonth" }
    it { expect( AnalyticsHelper::WORK_GLOBUS_DWNLDS_TO_DATE ).to eq "WorkGlobusDownloadsToDate" }
    it { expect( AnalyticsHelper::WORK_ZIP_DWNLDS_PER_MONTH ).to eq "WorkZipDownloadsPerMonth" }
    it { expect( AnalyticsHelper::WORK_ZIP_DWNLDS_TO_DATE ).to eq "WorkZipDownloadsToDate" }

    it { expect( AnalyticsHelper::DOWNLOAD_EVENT ).to eq "Hyrax::DownloadsController#show" }
    it { expect( AnalyticsHelper::WORK_GLOBUS_EVENT ).to eq "Hyrax::DataSetsController#globus_download_redirect" }
    it { expect( AnalyticsHelper::WORK_SHOW_EVENT ).to eq "Hyrax::DataSetsController#show" }
    it { expect( AnalyticsHelper::WORK_ZIP_DOWNLOAD_EVENT ).to eq "Hyrax::DataSetsController#zip_download" }

    it { expect( AnalyticsHelper::MONTHLY_EVENTS_REPORT_EVENT_NAME_TO_LABEL_MAP ).to eq(
                                      { "Hyrax::DataSetsController#show" => "Visits",
                                        "Hyrax::DataSetsController#zip_download" => "Zip Downloads",
                                        "Hyrax::DataSetsController#globus_download_redirect" => "Globus Downloads" } ) }
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
    let( :time ) { Time.utc( 2019, 5, 6, 1, 2, 3 ) }
    let( :month_begin ) { Time.utc( 2019, 5, 1 ).beginning_of_day }
    let( :month_end ) { Time.utc( 2019, 5, 31 ).end_of_day }
    subject { AnalyticsHelper.date_range_for_month_of( time: time ) }
    it { expect( subject ).to eq( month_begin..month_end ) }
  end

  describe '.date_range_for_month_previous' do
    let( :time ) { Time.now.getgm - 1.month } # different time diff as starting point than #date_range_for_month_previous
    let( :month_begin ) { time.beginning_of_month }
    let( :month_end ) { time.end_of_month.end_of_day }
    subject { AnalyticsHelper.date_range_for_month_previous }
    it { expect( subject ).to eq( month_begin..month_end ) }
  end

  describe '.email_to_user', skip: true do
    subject { AnalyticsHelper.email_to_user( user.email ) }
    it { expect( subject ).to eq( user ) }
  end

  describe '.email_to_user_id' do
    subject { AnalyticsHelper.email_to_user_id( user.email ) }
    it { expect( subject ).to eq( user.id ) }
  end

  describe '.events_by_date' do
    let( :name ) { "event_name" }
    let( :cc_id ) { "123456789" }
    let( :data_name ) { 'Data Name' }
    let( :today_begin ) { Time.now.getgm.beginning_of_day }
    let( :today_end ) { Time.now.getgm.end_of_day }
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

    context "for admins" do
      let(:user ) { FactoryBot.create(:admin) }
      let(:ability ) { Ability.new user }

      context "is false when Flipflop.enable_local_analytics_ui? is false" do
        before do
          expect( AnalyticsHelper ).to receive( :enable_local_analytics_ui? ).and_return false
        end
        subject { AnalyticsHelper.show_hit_graph?( ability ) }
        it { expect( subject ).to eq false }
      end

      context "Flipflop.enable_local_analytics_ui? is true for admins" do
        before do
          expect( AnalyticsHelper ).to receive( :enable_local_analytics_ui? ).and_return true
          expect( ::Deepblue::AnalyticsIntegrationService ).to receive( :hit_graph_view_level ).and_return 1
          expect( ability ).to receive( :admin? ).and_return true
        end
        subject { AnalyticsHelper.show_hit_graph?( ability ) }
        it { expect( subject ).to eq true }
      end

    end

    context "for editors" do
      let(:user ) { FactoryBot.create(:user) }
      let(:ability ) { Ability.new user }

      context "is false when Flipflop.enable_local_analytics_ui? is false" do
        before do
          expect( AnalyticsHelper ).to receive( :enable_local_analytics_ui? ).and_return false
        end
        subject { AnalyticsHelper.show_hit_graph?( ability ) }
        it { expect( subject ).to eq false }
      end

      context "Flipflop.enable_local_analytics_ui? is true for admins" do
        before do
          expect( AnalyticsHelper ).to receive( :enable_local_analytics_ui? ).and_return true
          expect( ::Deepblue::AnalyticsIntegrationService ).to receive( :hit_graph_view_level ).and_return 2
          expect( ability ).to receive( :admin? ).and_return true
        end
        subject { AnalyticsHelper.show_hit_graph?( ability ) }
        it { expect( subject ).to eq true }
      end

      context "Flipflop.enable_local_analytics_ui? is true for editors" do
        let( :presenter ) { double( "presenter" ) }
        before do
          expect( AnalyticsHelper ).to receive( :enable_local_analytics_ui? ).and_return true
          expect( ::Deepblue::AnalyticsIntegrationService ).to receive( :hit_graph_view_level ).and_return 2
          allow( ability ).to receive( :admin? ).and_return false
          expect( presenter ).to receive( :can_subscribe_to_analytics_reports? ).and_return true
        end
        subject { AnalyticsHelper.show_hit_graph?( ability, presenter: presenter ) }
        it { expect( subject ).to eq true }
      end

    end

    context "for users" do
      let(:user ) { FactoryBot.create(:user) }
      let(:ability ) { Ability.new user }

      context "is false when Flipflop.enable_local_analytics_ui? is false" do
        before do
          expect( AnalyticsHelper ).to receive( :enable_local_analytics_ui? ).and_return false
        end
        subject { AnalyticsHelper.show_hit_graph?( ability ) }
        it { expect( subject ).to eq false }
      end

      context "Flipflop.enable_local_analytics_ui? is true for everyone" do
        let( :presenter ) { double( "presenter" ) }
        before do
          expect( AnalyticsHelper ).to receive( :enable_local_analytics_ui? ).and_return true
          expect( ::Deepblue::AnalyticsIntegrationService ).to receive( :hit_graph_view_level ).and_return 3
          allow( ability ).to receive( :admin? ).and_return false
          allow( presenter ).to receive( :editor? ).and_return false
        end
        subject { AnalyticsHelper.show_hit_graph?( ability, presenter: presenter ) }
        it { expect( subject ).to eq true }
      end

    end

  end

  describe '.update_current_month_condensed_events' do
    let( :month_begin ) { Time.now.getgm.beginning_of_month }
    let( :this_months_date_range ) { month_begin.beginning_of_day..month_begin.end_of_month.end_of_day }
    let( :return_value ) { []  }

    context 'it calls' do
      subject { described_class.update_current_month_condensed_events }
      before do
        expect( described_class).to receive( :update_condensed_events_for ).with( date_range: this_months_date_range ).and_return return_value
      end
      it { expect( subject ).to eq return_value }
    end

  end

  describe '.update_condensed_events_for', skip: true do
    # we care about: Ahoy::Event.select( :name, :cc_id ).where( time: date_range )
    # create events
    # create date range
    # Ahoy::CondensedEvent.new( name: name, cc_id: cc_id, date_begin: date_range.first, date_end: date_range.last )
  end

end
