require 'rails_helper'

RSpec.describe Hyrax::Actors::EnvironmentAttributes, skip: false do

  let(:user)    { factory_bot_create_user(:user) }
  let(:work)    { create(:data_set, user: user) }
  let(:ability) { Ability.new(user) }

  it { expect( Hyrax::Actors::EnvironmentAttributes::ENVIRONMENT_ATTRIBUTES_DEBUG_VERBOSE ).to eq false }

  # describe "#initialize" do
  #   let(:env) { described_class.allocate }
  #
  #   context "with has attributes" do
  #     let(:attributes) { { 'params' => [] } }
  #
  #     before do
  #       # expect(env).to receive(:initialize).and_return env
  #     end
  #
  #     it "calls initialize and has the expected values" do
  #       env.send(:initialize, curation_concern: work,
  #                current_ability: ability,
  #                attributes: attributes,
  #                action: nil, wants_format: nil )
  #       expect( env.curation_concern ).to eq work
  #       expect( env.current_ability ).to eq ability
  #       expect( env.attributes ).to eq attributes.with_indifferent_access
  #       expect(env.user).to eq user
  #     end
  #
  #   end
  #
  #   context 'with environment attributes' do
  #     let(:attributes) { { 'params' => [] } }
  #
  #     before do
  #       # expect(env).to receive(:initialize).and_return env
  #     end
  #
  #     it "calls initialize and has the expected values" do
  #       env.send(:initialize, curation_concern: work,
  #                current_ability: ability,
  #                attributes: attributes,
  #                action: nil, wants_format: nil )
  #       expect( env.curation_concern ).to eq work
  #       expect( env.current_ability ).to eq ability
  #       expect( env.attributes ).to eq attributes.with_indifferent_access
  #       expect(env.user).to eq user
  #     end
  #
  #   end
  #
  # end

end
