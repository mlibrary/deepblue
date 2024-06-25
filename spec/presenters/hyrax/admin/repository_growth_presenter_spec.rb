# frozen_string_literal: true
# Update: hyrax4

require 'rails_helper'

RSpec.describe Hyrax::Admin::RepositoryGrowthPresenter, skip: false do
  let(:start_date) { 2.days.ago }
  let(:end_date) { Time.zone.now }
  let(:instance) { described_class.new(start_date, end_date) }

  describe "#to_json" do
    subject { instance.to_json }

    let(:works) do
      instance_double(Hyrax::Statistics::Works::OverTime,
                      points: [['2017-02-16', '12']])
    end
    let(:collections) do
      instance_double(Hyrax::Statistics::Collections::OverTime,
                      points: [['2017-02-16', '3']])
    end

    before do
      allow(Hyrax::Statistics::Works::OverTime).to receive(:new).and_return(works)
      allow(Hyrax::Statistics::Collections::OverTime).to receive(:new).and_return(collections)
    end

    it "returns points" do
      expect(subject).to eq "[{\"y\":\"2017-02-16\",\"works\":\"12\",\"collections\":\"3\"}]"
    end
  end
end
