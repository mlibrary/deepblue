# frozen_string_literal: true
RSpec.shared_examples "a DOI-enabled solr document" do
  let(:document) { solr_document_class.new(attributes) }
  let(:attributes) { {} }

  describe "doi" do
    it 'returns nil if not present' do
      expect(document.doi).to eq nil
    end

    context 'when present' do
      let(:doi) { '10.1234/abc' }
      let(:attributes) { { doi_ssi: doi } }

      it 'returns the doi' do
        expect(document.doi).to eq doi
      end
    end
  end
end
