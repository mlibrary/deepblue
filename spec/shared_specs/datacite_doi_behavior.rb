# frozen_string_literal: true
RSpec.shared_examples "a DataCite DOI-enabled model" do
  subject { work }

  let(:properties) do
    [:doi_status_when_public]
  end

  describe "properties" do
    it "has DataCite DOI properties" do
      properties.each do |property|
        expect(subject).to respond_to(property)
      end
    end
  end

  describe 'validations' do
    it 'validates inclusion of doi_status_when_public' do
      expect(subject).to validate_inclusion_of(:doi_status_when_public).in_array([nil] + ::Deepblue::DataCiteRegistrar::STATES).allow_nil
    end
  end

  describe 'to_solr' do
    let(:solr_doc) { subject.to_solr }

    let(:solr_fields) do
      [:doi_status_when_public_ssi]
    end

    before do
      work.doi_status_when_public = 'draft'
    end

    it 'has solr fields' do
      solr_fields.each do |field|
        expect(solr_doc.fetch(field.to_s)).not_to be_blank
      end
    end
  end
end
