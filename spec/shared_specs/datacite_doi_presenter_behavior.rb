# frozen_string_literal: true
RSpec.shared_examples "a DataCite DOI-enabled presenter" do
  subject { presenter }

  let(:presenter) { presenter_class.new(solr_document, nil, nil) }
  let(:solr_document) { instance_double(solr_document_class) }

  it { is_expected.to delegate_method(:doi_status_when_public).to(:solr_document) }

  describe 'doi_status' do
    before do
      allow(solr_document).to receive(:doi_status_when_public).and_return(doi_status_when_public)
    end

    let(:doi_status_when_public) { 'draft' }

    context 'when findable' do
      let(:doi_status_when_public) { 'findable' }

      context 'when public' do
        it 'is findable' do
          allow(solr_document).to receive(:public?).and_return(true)
          expect(subject.doi_status).to eq 'findable'
        end
      end

      context 'when not public' do
        it 'is registered' do
          allow(solr_document).to receive(:public?).and_return(false)
          expect(subject.doi_status).to eq 'registered'
        end
      end
    end

    it 'returns the status' do
      expect(subject.doi_status).to eq doi_status_when_public
    end
  end
end
