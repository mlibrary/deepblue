# frozen_string_literal: true
# hyrax5 - copied, updated

RSpec.describe Hyrax::Works::ManagedWorksService, clean_repo: true, skip: Rails.configuration.hyrax5_spec_skip do
  let(:current_ability) { instance_double(Ability, admin?: true) }
  let(:scope) { FakeSearchBuilderScope.new(current_ability: current_ability) }

  describe '.managed_works_count' do
    #hyrax5 - let!(:work) { valkyrie_create(:monograph, :public) }
    let(:user) { factory_bot_create_user(:user) }
    let(:work) { create(:data_set, id: 'abc12345xy', user: user) }

    it 'returns number of works that can be managed' do
      expect(described_class.managed_works_count(scope: scope)).to eq(1)
    end
  end
end
