# frozen_string_literal: true
RSpec.shared_examples "a DOI-enabled form" do
  subject { form }

  describe "properties" do
    it { is_expected.to delegate_method(:doi).to(:model) }

    it 'includes properties in the list of terms' do
      expect(subject.terms).to include(:doi)
    end

    it 'does not include properties in primary or secondary' do
      expect(subject.primary_terms).not_to include(:doi)
      expect(subject.secondary_terms).not_to include(:doi)
    end
  end
end
