# frozen_string_literal: true

require 'rails_helper'

describe Deepblue::DoiMintingService do

  context "when minting a new doi" do
    subject { described_class.new(work) }
    let(:work) { mock_model(GenericWork, id: '123', title: ['demotitle'],
                                         creator: ['Smith, John', 'Smith, Jane', 'O\'Rielly, Kelly'])}
    let(:work_url) { "umrdr-testing.hydra.lib.umich.edu/concern/work/#{work.id}" }
    let(:dummy_doi) { "doi:10.5072/FK2DEAD455BEEF" }
    let(:identifier) { instance_double(Ezid::Identifier, id: dummy_doi) }

    before do
      allow(Rails).to receive_message_chain("application.routes.url_helpers.hyrax_data_set_url").and_return(work_url)
      allow(work).to receive(:save)
      allow(work).to receive(:doi).and_return(identifier.id)
      allow(work).to receive(:doi=)
      allow(subject).to receive(:doi_server_reachable?).and_return(true)
      allow(Ezid::Identifier).to receive(:mint).and_return(identifier)
    end

    it "has expected metadata" do
      expect(subject.metadata.datacite_title).to eq(work.title.first)
      expect(subject.metadata.datacite_publisher).to eq(described_class::PUBLISHER)
      expect(subject.metadata.datacite_publicationyear).to eq(Date.today.year.to_s)
      expect(subject.metadata.datacite_resourcetype).to eq(described_class::RESOURCE_TYPE)
      expect(subject.metadata.datacite_creator).to eq(work.creator.join(';'))
      expect(subject.metadata.target).not_to be_empty
    end

    it "calls out to EZID to mint a doi" do
      expect(Ezid::Identifier).to receive(:mint)
      subject.run
    end

    it "returns the id value of the identifier" do
      expect(subject.run).to eq(identifier.id)
    end

    it "assigns the doi value and saves the work" do
      expect(work).to receive(:doi=).with(identifier.id)
      expect(work).to receive(:save)
      subject.run
    end

    context "EZID service is unreachable" do
      before do
        allow(subject).to receive(:doi_server_reachable?).and_return(false)
      end
      it "does not attempt to mint a doi" do
        expect(subject).not_to receive(:mint_doi)
        expect(subject.run).to be_nil
      end
    end
  end

  context "when actually calling out to service" do
    let(:work) { GenericWork.new(id: '123', title: ['demotitle'],
                                 creator: ['Smith, John', 'Smith, Jane', 'O\'Rielly, Kelly'])}
    it "mints a doi" do
      skip unless ENV['INTEGRATION']
      expect(described_class.mint_doi_for(work)).to start_with 'doi:10.5072/FK2'
    end
  end

end
