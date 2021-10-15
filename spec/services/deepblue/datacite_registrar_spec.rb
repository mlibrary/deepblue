# frozen_string_literal: true

require 'rails_helper'

require_relative '../../../app/services/deepblue/datacite_registrar'
require_relative '../../../app/services/deepblue/doi_minting_2021_service'

describe ::Deepblue::DataCiteRegistrar, :datacite_api do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.data_cite_registrar_debug_verbose ).to eq( debug_verbose )
      expect( ::Deepblue::DoiMintingService.data_cite_registrar_debug_verbose ).to eq( debug_verbose )
    end
  end

  let(:registrar) { ::Deepblue::DataCiteRegistrar.new }
  let(:username)  { 'username' }
  let(:password)  { 'password' }
  let(:prefix)    { '10.1234' }
  let(:draft_doi) { "#{prefix}/draft-doi" }
  let(:registered_doi) { "#{prefix}/registered-doi" }
  let(:findable_doi)   { "#{prefix}/findable-doi" }
  # let(:model_class) do
  #   Class.new(DataSet) do
  #     include Deepblue::DoiBehavior
  #     include Deepblue::DataCiteDoiBehavior
  #
  #     # Defined here for polymorphic_url
  #     def self.name
  #       "DataSet"
  #     end
  #   end
  # end
  let(:work) { create(:data_set, attributes) }
  let(:attributes) do
    {
      title: [title],
      creator: [creator],
      publisher: [publisher],
      description: [description],
      doi: doi
    }
  end
  let(:title) { 'Moomin' }
  let(:creator) { 'Tove Jansson' }
  let(:publisher) { 'Schildts' }
  let(:description) { 'Swedish comic about the adventures of the residents of Moominvalley.' }
  let(:doi) { draft_doi }

  before do
    ::Deepblue::DataCiteRegistrar.username = username
    ::Deepblue::DataCiteRegistrar.password = password
    ::Deepblue::DataCiteRegistrar.prefix = prefix
    ::Deepblue::DataCiteRegistrar.mode = :test
  end

  describe 'initialize' do
    it 'sets a default builder with the configured prefix' do
      expect(registrar.builder.prefix).to eq prefix
    end
  end

  describe 'register!' do
    context 'with a non-DOI enabled work' do
      let(:work) { DataSet.new }

      it 'returns a nil indentifer' do
        expect(registrar.register!(object: work).identifier).to eq nil
      end
    end

    context 'when doi_status_when_public is nil' do
      context 'doi is nil' do
        let(:doi) { nil }

        it 'returns a nil identifer' do
          expect(registrar.register!(object: work).identifier).to eq nil
        end
      end

      context 'doi is supplied' do
        it 'returns supplied doi' do
          expect(registrar.register!(object: work).identifier).to eq doi
        end
      end
    end

    context 'when doi_status_when_public is draft', skip: true do
      before do
        work.doi_status_when_public = 'draft'
      end

      context 'doi is nil' do
        let(:doi) { nil }

        it 'returns a new doi' do
          expect(registrar.register!(object: work).identifier).to match ::Deepblue::DoiBehavior.doi_regex
        end
      end

      context 'doi is supplied' do
        it 'returns supplied doi' do
          expect(registrar.register!(object: work).identifier).to eq doi
        end
      end
    end

    context 'when doi_status_when_public is registered', skip: true do
      before do
        work.doi_status_when_public = 'registered'
        allow(registrar.send(:client)).to receive(:register_url).and_call_original
      end

      context 'doi is nil' do
        let(:doi) { nil }

        it 'returns a new doi' do
          expect(registrar.register!(object: work).identifier).to match ::Deepblue::DoiBehavior.doi_regex
          expect(registrar.send(:client)).to have_received(:register_url).with(::Deepblue::DoiBehavior.doi_regex, String)
        end
      end

      context 'doi is supplied' do
        it 'returns supplied doi' do
          expect(registrar.register!(object: work).identifier).to eq doi
          expect(registrar.send(:client)).to have_received(:register_url).with(::Deepblue::DoiBehavior.doi_regex, String)
        end
      end
    end

    context 'when doi_status_when_public is findable', skip: true do
      before do
        work.doi_status_when_public = 'findable'
        allow(registrar.send(:client)).to receive(:register_url).and_call_original
        allow(registrar.send(:client)).to receive(:delete_metadata).and_call_original
      end

      context 'doi is nil' do
        let(:doi) { nil }

        it 'returns a new doi' do
          expect(registrar.register!(object: work).identifier).to match ::Deepblue::DoiBehavior.doi_regex
          expect(registrar.send(:client)).to have_received(:register_url).with(::Deepblue::DoiBehavior.doi_regex, String)
        end
      end

      context 'doi is supplied' do
        it 'returns supplied doi' do
          expect(registrar.register!(object: work).identifier).to eq doi
          expect(registrar.send(:client)).to have_received(:register_url).with(::Deepblue::DoiBehavior.doi_regex, String)
        end
      end

      context 'work is public' do
        before do
          work.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        end

        it 'does not call delete metadata' do
          expect(registrar.register!(object: work).identifier).to eq doi
          expect(registrar.send(:client)).to have_received(:register_url).with(::Deepblue::DoiBehavior.doi_regex, String)
          expect(registrar.send(:client)).not_to have_received(:delete_metadata)
        end
      end

      context 'work is not public' do
        it 'calls delete metadata to downgrade doi to registered' do
          expect(registrar.register!(object: work).identifier).to eq doi
          expect(registrar.send(:client)).to have_received(:register_url).with(::Deepblue::DoiBehavior.doi_regex, String)
          expect(registrar.send(:client)).to have_received(:delete_metadata).with(work.doi)
        end
      end
    end
  end

  describe 'mint_draft_doi' do
    it 'returns a draft doi' do
      expect(registrar.mint_draft_doi).to eq draft_doi
    end
  end
end
