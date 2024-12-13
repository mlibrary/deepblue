# frozen_string_literal: true
# Update: hyrax4
# Updated: hyrax5

require 'rails_helper'

RSpec.describe Hyrax::Admin::DashboardPresenter, skip: Rails.configuration.hyrax5_spec_skip do
  let(:instance) { described_class.new }
  let(:start_date) { 2.days.ago }
  let(:end_date) { Time.zone.now }

  describe "#user_count" do
    before do
      factory_bot_create_user(:user)
      factory_bot_create_user(:user)
      factory_bot_create_user(:user, :guest)
    end

    subject { instance.user_count(start_date, end_date) }

    it { is_expected.to eq 2 }
  end

  describe "#repository_objects" do
    subject { instance.repository_objects }

    it { is_expected.to be_kind_of Hyrax::Admin::RepositoryObjectPresenter }
  end

  describe "#repository_growth" do
    subject { instance.repository_growth(start_date, end_date) }

    it { is_expected.to be_kind_of Hyrax::Admin::RepositoryGrowthPresenter }
  end

  describe "#user_activity" do
    subject { instance.user_activity(start_date, end_date) }

    it { is_expected.to be_kind_of Hyrax::Admin::UserActivityPresenter }
  end
end
