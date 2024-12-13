require 'rails_helper'

module MusicalWork
  class Cover < ActiveFedora::Base
  end
end

class Hyrax::Actors::MusicalWork
  class CoverActor < ::Hyrax::Actors::AbstractActor
  end
end

RSpec.describe Hyrax::Actors::ModelActor, skip: false do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.model_actor_debug_verbose ).to eq debug_verbose
    end
  end

  let(:work) { MusicalWork::Cover.new }
  let(:depositor) { factory_bot_create_user(:user) }
  let(:depositor_ability) { ::Ability.new(depositor) }
  let(:env) { Hyrax::Actors::Environment.new(work, depositor_ability, {}) }

  describe '#model_actor' do
    subject { described_class.new('¯\_(ツ)_/¯').send(:model_actor, env) }

    it "preserves the namespacing" do
      is_expected.to be_kind_of Hyrax::Actors::MusicalWork::CoverActor
    end
  end

end
