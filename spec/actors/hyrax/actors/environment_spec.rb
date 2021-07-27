require 'rails_helper'

RSpec.describe Hyrax::Actors::Environment, skip: false do

  let(:user)    { create(:user) }
  let(:work)    { create(:data_set, user: user) }
  let(:ability) { Ability.new(user) }

  describe "#initialize" do
    let(:env) { described_class.allocate }

    context "with has attributes" do
      let(:attributes) { { 'params' => [] } }

      before do
        # expect(env).to receive(:initialize).and_return env
      end

      it "calls initialize and has the expected values" do
        env.send(:initialize, work, ability, attributes )
        expect( env.curation_concern ).to eq work
        expect( env.current_ability ).to eq ability
        expect( env.attributes ).to eq attributes.with_indifferent_access
        expect(env.user).to eq user
      end

    end

    context 'with environment attributes' do
      let(:attributes) { { 'params' => [] } }

      before do
        # expect(env).to receive(:initialize).and_return env
      end

      it "calls initialize and has the expected values" do
        env.send(:initialize, work, ability, attributes )
        expect( env.curation_concern ).to eq work
        expect( env.current_ability ).to eq ability
        expect( env.attributes ).to eq attributes.with_indifferent_access
        expect(env.user).to eq user
      end

    end

  end

end
