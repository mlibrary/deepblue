require 'rails_helper'

RSpec.describe Hyrax::Actors::EmbargoActor, skip: true do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.embargo_actor_debug_verbose ).to eq debug_verbose
    end
  end

  let(:work) do
    DataSet.new do |work|
      work.apply_depositor_metadata 'foo'
      work.title = ["test"]
      work.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      work.visibility_during_embargo = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      work.visibility_after_embargo = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      work.embargo_release_date = release_date.to_s
      work.save(validate: false)
    end
  end
  let(:attributes) { {} }
  let(:user)    { create(:admin) }
  let(:ability) { Ability.new(user) }
  let(:env)     { Hyrax::Actors::Environment.new(work, ability, attributes) }
  let(:actor)   { described_class.new(env, work) }

  describe "#destroy" do
    context "with an active embargo" do
      let(:release_date) { Time.zone.today + 2 }

      it "removes the embargo" do
        actor.destroy
        expect(work.reload.embargo_release_date).to be_nil
        expect(work.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      end
    end

    context 'with an expired embargo' do
      let(:release_date) { Time.zone.today - 2 }

      it "removes the embargo" do
        actor.destroy
        expect(work.reload.embargo_release_date).to be_nil
        expect(work.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      end
    end
  end
end
