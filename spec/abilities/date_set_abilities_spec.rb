require 'rails_helper'
require 'cancan/matchers'

RSpec.describe 'User' do
  describe 'Abilities' do
    subject { Ability.new(current_user) }

    let(:data_set) { create(:private_data_set, user: creating_user) }
    let(:user) { create(:user) }

    describe 'without embargo' do
      describe 'creator of object' do
        let(:creating_user) { user }
        let(:current_user) { user }

        it do
          is_expected.to be_able_to(:create, DataSet.new)
          is_expected.to be_able_to(:read, data_set)
          is_expected.to be_able_to(:update, data_set)
          is_expected.to be_able_to(:destroy, data_set)
        end
      end

      describe 'as a repository manager' do
        let(:manager_user) { create(:admin) }
        let(:creating_user) { user }
        let(:current_user) { manager_user }

        it do
          is_expected.to be_able_to(:create, DataSet.new)
          is_expected.to be_able_to(:read, data_set)
          is_expected.to be_able_to(:update, data_set)
          is_expected.to be_able_to(:destroy, data_set)
        end
      end

      describe 'another authenticated user' do
        let(:creating_user) { create(:user) }
        let(:current_user) { user }

        it do
          is_expected.to be_able_to(:create, DataSet.new)
          is_expected.not_to be_able_to(:read, data_set)
          is_expected.not_to be_able_to(:update, data_set)
          is_expected.not_to be_able_to(:destroy, data_set)
          is_expected.to be_able_to(:collect, data_set)
        end
      end

      describe 'a nil user' do
        let(:creating_user) { create(:user) }
        let(:current_user) { nil }

        it do
          is_expected.not_to be_able_to(:create, DataSet.new)
          is_expected.not_to be_able_to(:read, data_set)
          is_expected.not_to be_able_to(:update, data_set)
          is_expected.not_to be_able_to(:destroy, data_set)
          is_expected.not_to be_able_to(:collect, data_set)
        end
      end
    end
  end
end
