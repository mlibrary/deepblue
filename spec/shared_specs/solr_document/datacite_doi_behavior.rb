# frozen_string_literal: true
RSpec.shared_examples "a DataCite DOI-enabled solr document" do
  let(:document) { solr_document_class.new(attributes) }
  let(:attributes) { {} }

  describe "doi_status_when_pubic" do
    it 'returns nil if not present' do
      expect(document.doi_status_when_public).to eq nil
    end

    context 'when present' do
      let(:doi_status_when_public) { 'findable' }
      let(:attributes) { { doi_status_when_public_ssi: doi_status_when_public } }

      it 'returns doi_status_when_public' do
        expect(document.doi_status_when_public).to eq doi_status_when_public
      end
    end
  end
end
