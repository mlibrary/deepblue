require 'rails_helper'
require 'cancan/matchers'

RSpec.describe 'Abilities for Operations', type: :model do
  describe "a registered user" do
    subject { Ability.new(user) }

    let(:user) { factory_bot_create_user(:user) }

    it { is_expected.to be_able_to(:read, build(:operation, user: user)) }
    it { is_expected.not_to be_able_to(:read, build(:operation)) }
  end
end
