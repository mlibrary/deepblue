# frozen_string_literal: true
# hyrax-orcid

require 'rails_helper'

RSpec.describe Hyrax::Orcid::Profile::EmploymentPresenter do
  let(:service) { described_class.new(reader.read_employment) }
  let(:reader) { Hyrax::Orcid::Record::ReaderService.new(orcid_identity) }

  let(:user) { factory_bot_create_user(:user) }
  let!(:orcid_identity) { create(:orcid_identity, work_sync_preference: "sync_all", user: user) }
  # let(:base_dir) { '..' }
  let(:base_dir) { 'spec' }
  let(:record_response_body) { File.read Rails.root.join(base_dir, "fixtures", "orcid", "json", "reader_service_record.json") }
  let(:record_response) { instance_double(Faraday::Response, body: record_response_body, headers: {}, success?: true) }

  before do
    orcid_identity

    allow(reader).to receive(:perform_record_request).and_return(record_response)
  end

  describe "#key" do
    it { expect(service.key).to eq "employment" }
  end

  describe "#collection" do
    let(:result) { service.collection }

    it "returns a hash" do
      expect(result).to be_a(Array)
      expect(result.first).to be_a(Hash)
      expect(result.count).to be 1
      expect(result.first.keys).to eq [:title, :items]
      expect(result.first.dig(:title)).to eq "Role"
      expect(result.first.dig(:items).first).to eq "2012-07-01 - 2017-01-01"
    end
  end
end
