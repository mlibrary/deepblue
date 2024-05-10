# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::Actors::CleanupFileSetsActor, skip: false do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.cleanup_file_sets_actor_debug_verbose ).to eq debug_verbose
    end
  end

  let(:ability) { ::Ability.new(depositor) }
  let(:env) { Hyrax::Actors::Environment.new(work, ability, attributes) }
  let(:terminator) { Hyrax::Actors::Terminator.new }
  let(:depositor) { create(:user) }
  let(:attributes) { {} }

  subject(:middleware) do
    stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
      middleware.use described_class
    end
    stack.build(terminator)
  end

  describe "#destroy" do
    subject { middleware.destroy(env) }

    let!(:work) { create(:data_set_with_one_file) }

    it 'removes all  file sets' do
      expect { middleware.destroy(env) }.to change { FileSet.count }.by(-1)
    end
  end
end
