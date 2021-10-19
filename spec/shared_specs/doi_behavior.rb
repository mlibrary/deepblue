# frozen_string_literal: true
RSpec.shared_examples "a DOI-enabled model" do
  subject { work }

  let(:properties) do
    [:doi]
  end

  describe "properties" do
    it "has DOI properties" do
      properties.each do |property|
        expect(subject).to respond_to(property)
      end
    end
  end

  describe 'validations' do
    describe 'validates format of doi' do
      let(:valid_dois) { ['10.1234/abc', '10.1234.100/abc-def', '10.1234/1', '10.1234/doi/with/more/slashes'] }
      let(:invalid_dois) { ['10.123/abc', 'https://doi.org/10.1234/abc', '10.1234/abc def', ''] }

      it 'accepts valid dois' do
        expect(subject).to allow_value([]).for(:doi)
        expect(subject).to allow_value(nil).for(:doi)
        expect(subject).to allow_value(valid_dois).for(:doi)
      end

      it 'rejects invalid dois' do
        invalid_dois.each do |invalid_doi|
          expect(subject).not_to allow_values([invalid_doi]).for(:doi)
        end
      end
    end
  end

  describe 'to_solr' do
    let(:solr_doc) { subject.to_solr }

    let(:solr_fields) do
      [:doi_ssi]
    end

    before do
      work.doi = ["10.1234/abc"]
    end

    it 'has solr fields' do
      solr_fields.each do |field|
        expect(solr_doc.fetch(field.to_s)).not_to be_blank
      end
    end
  end

  describe 'methods' do
    it "doi_registrar is string or nil" do
      expect(subject.doi_registrar).to be_a(String).or be_nil
    end

    it 'doi_registrar_opts is a hash' do
      expect(subject.doi_registrar_opts).to be_a Hash
    end
  end
end
