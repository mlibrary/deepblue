# frozen_string_literal: true
RSpec.shared_examples "a DataCite DOI-enabled form" do
  subject { form }

  describe "properties" do
    it { is_expected.to delegate_method(:doi_status_when_public).to(:model) }

    it 'includes properties in the list of terms' do
      expect(subject.terms).to include(:doi_status_when_public)
    end

    it 'does not include properties in primary or secondary' do
      expect(subject.primary_terms).not_to include(:doi_status_when_public)
      expect(subject.secondary_terms).not_to include(:doi_status_when_public)
    end
  end
end
