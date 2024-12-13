# frozen_string_literal: true
require 'rails_helper'
require 'cancan/matchers'

RSpec.describe Hyrax::Ability, type: :model do
  context "with a registered user" do
    let(:user) { factory_bot_create_user(:user) }

    subject { Ability.new(user) }

    it { is_expected.not_to be_able_to(:read, :admin_dashboard) }
  end
  context "with an administrative user" do
    let(:user) { factory_bot_create_user(:admin) }

    subject { Ability.new(user) }

    it { is_expected.to be_able_to(:read, :admin_dashboard) }
  end
end
