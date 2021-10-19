# frozen_string_literal: true
RSpec.shared_examples "a DOI-enabled presenter" do
  subject { presenter }

  let(:presenter) { presenter_class.new(solr_document, nil, nil) }
  let(:solr_document) { instance_double(solr_document_class) }

  describe 'doi' do
    let(:doi) { '10.1234/abc' }

    before do
      allow(solr_document).to receive(:doi).and_return(doi)
    end

    it 'returns a doi url' do
      expect(subject.doi).to eq "https://doi.org/#{subject.solr_document.doi}"
    end
  end
end
