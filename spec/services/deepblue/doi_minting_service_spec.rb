# frozen_string_literal: true

require 'rails_helper'

require_relative '../../../app/services/deepblue/doi_minting_service'

RSpec.describe ::Deepblue::DoiMintingService do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.doi_minting_service_debug_verbose ).to eq( debug_verbose )
      expect( described_class.doi_minting_job_debug_verbose     ).to eq( debug_verbose )
      expect( described_class.register_doi_job_debug_verbose    ).to eq( debug_verbose )
    end
  end

  let(:doi_minting_2021_service_enabled) { false }

  describe 'module variables' do
    it { expect(described_class.doi_minting_2021_service_enabled).to eq doi_minting_2021_service_enabled }
    it { expect(described_class.doi_minting_service_email_user_on_success).to eq false }
  end

  context "when minting a new doi using old system" do
    subject { described_class.new( curation_concern: work,
                                   current_user: "test_doi_minting_service@umich.edu",
                                   target_url: work_url ) }
    let(:work) { mock_model(DataSet, id: '123', title: ['demotitle'],
                                         creator: ['Smith, John', 'Smith, Jane', 'O\'Rielly, Kelly'])}
    let(:work_url) { "umrdr-testing.hydra.lib.umich.edu/concern/work/#{work.id}" }
    let(:dummy_doi) { "doi:10.5072/FK2DEAD455BEEF" }
    let(:identifier) { instance_double(Ezid::Identifier, id: dummy_doi) }

    before do
      described_class.doi_minting_2021_service_enabled = false
      allow(Rails).to receive_message_chain("application.routes.url_helpers.hyrax_data_set_url").and_return(work_url)
      allow(work).to receive(:save)
      allow(work).to receive(:reload)
      allow(work).to receive(:doi).and_return(identifier.id)
      allow(work).to receive(:doi=)
      allow(work).to receive(:provenance_mint_doi)
      allow(work).to receive(:work?).and_return(true)
      allow(work).to receive(:for_event_url).and_return(work_url)
      allow(subject).to receive(:doi_server_reachable?).and_return(true)
      allow(Ezid::Identifier).to receive(:mint).and_return(identifier)
    end

    after do
      described_class.doi_minting_2021_service_enabled = doi_minting_2021_service_enabled
    end

    it "has expected metadata" do
      expect(subject.metadata.datacite_title).to eq(work.title.first)
      expect(subject.metadata.datacite_publisher).to eq(described_class.doi_publisher_name)
      expect(subject.metadata.datacite_publicationyear).to eq(Date.today.year.to_s)
      expect(subject.metadata.datacite_resourcetype).to eq(described_class.doi_resource_type)
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
        expect(subject.run).to eq "doi:10.5072/FK2DEAD455BEEF"
      end
    end
  end

  context "when minting a new doi using new system" do
    subject { described_class.new( curation_concern: work,
                                   current_user: "test_doi_minting_service@umich.edu",
                                   target_url: work_url ) }
    let(:work) { mock_model(DataSet, id: '123', title: ['demotitle'],
                            creator: ['Smith, John', 'Smith, Jane', 'O\'Rielly, Kelly'])}
    let(:work_url) { "umrdr-testing.hydra.lib.umich.edu/concern/work/#{work.id}" }
    let(:dummy_doi) { "doi:10.5072/FK2DEAD455BEEF" }
    let(:identifier) { instance_double(Ezid::Identifier, id: dummy_doi) }

    before do
      described_class.doi_minting_2021_service_enabled = true
      allow(Rails).to receive_message_chain("application.routes.url_helpers.hyrax_data_set_url").and_return(work_url)
      allow(work).to receive(:save)
      allow(work).to receive(:reload)
      allow(work).to receive(:doi).and_return(identifier.id)
      allow(work).to receive(:doi=)
      allow(work).to receive(:provenance_mint_doi)
      allow(work).to receive(:work?).and_return(true)
      allow(work).to receive(:for_event_url).and_return(work_url)
      allow(subject).to receive(:doi_server_reachable?).and_return(true)
      allow(Ezid::Identifier).to receive(:mint).and_return(identifier)
    end

    after do
      described_class.doi_minting_2021_service_enabled = doi_minting_2021_service_enabled
    end

    it "has expected metadata" do
      expect(subject.metadata.datacite_title).to eq(work.title.first)
      expect(subject.metadata.datacite_publisher).to eq(described_class.doi_publisher_name)
      expect(subject.metadata.datacite_publicationyear).to eq(Date.today.year.to_s)
      expect(subject.metadata.datacite_resourcetype).to eq(described_class.doi_resource_type)
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
        expect(subject.run).to eq "doi:10.5072/FK2DEAD455BEEF"
      end
    end
  end

  context "when actually calling out to service" do
    let(:work) { DataSet.new(id: '123', title: ['demotitle'],
                                 creator: ['Smith, John', 'Smith, Jane', 'O\'Rielly, Kelly'])}
    let( :current_user ) { "test_doi_minting_service@umich.edu" }
    it "mints a doi" do
      skip unless ENV['INTEGRATION']
      expect( described_class. mint_doi_for( curation_concern: work,
                                             current_user: current_user,
                                             target_url: work_url ) ).to start_with 'doi:10.5072/FK2'
    end
  end

end
