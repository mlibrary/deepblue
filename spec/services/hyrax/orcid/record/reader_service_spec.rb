# frozen_string_literal: true
# hyrax-orcid

require 'rails_helper'

RSpec.describe Hyrax::Orcid::Record::ReaderService do
  let(:service) { described_class.new(orcid_identity) }
  let(:user) { factory_bot_create_user(:user) }
  let!(:orcid_identity) { create(:orcid_identity, work_sync_preference: "sync_all", user: user) }
  # let(:base_dir) { '..' }
  let(:base_dir) { 'spec' }
  let(:record_response_body) { File.read Rails.root.join(base_dir, "fixtures", "orcid", "json", "reader_service_record.json") }
  let(:works_response_body) { File.read Rails.root.join(base_dir, "fixtures", "orcid", "json", "reader_service_works.json") }

  let(:record_response) { instance_double(Faraday::Response, body: record_response_body, headers: {}, success?: true) }
  let(:works_response) { instance_double(Faraday::Response, body: works_response_body, headers: {}, success?: true) }

  before do
    orcid_identity

    allow(service).to receive(:perform_record_request).and_return(record_response)
  end

  describe "#read_education" do
    let(:result) { service.read_education }

    it "returns an array of hashes" do
      expect(result).to be_a(Array)
      expect(result.first).to be_a(Hash)
      expect(result.count).to be 1
      expect(result.first.dig("organization", "name")).to eq "Massachusetts Institute of Technology"
    end
  end

  describe "#read_employment" do
    let(:result) { service.read_employment }

    it "returns an array of hashes" do
      expect(result).to be_a(Array)
      expect(result.first).to be_a(Hash)
      expect(result.count).to be 1
      expect(result.first.dig("organization", "name")).to eq "ORCID"
    end
  end

  describe "#read_funding" do
    let(:result) { service.read_funding }

    it "returns an array of hashes" do
      expect(result).to be_a(Array)
      expect(result.first).to be_a(Hash)
      expect(result.count).to be 1
      expect(result.first.dig("funding-summary").first.dig("organization", "name")).to eq "Wellcome Trust"
    end
  end

  describe "#read_peer_reviews" do
    let(:result) { service.read_peer_reviews }

    it "returns an array of hashes" do
      expect(result).to be_a(Array)
      expect(result.first).to be_a(Hash)
      expect(result.count).to be 1
      expect(result.first.dig("peer-review-summary").first.dig("convening-organization", "name")).to eq "ORCID"
    end
  end

  describe "#read_works" do
    let(:result) { service.read_works }

    before do
      allow(service).to receive(:perform_works_request).and_return(works_response)
    end

    it "returns an array of hashes" do
      expect(result).to be_a(Array)
      expect(result.first).to be_a(Hash)
      expect(result.count).to be 1
      expect(result.first.dig("work", "title", "title", "value")).to eq "Testing contributor with notify, work profile synced"
    end
  end
end
