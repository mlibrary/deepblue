require 'rails_helper'

RSpec.describe Hyrax::Actors::DataSetActor do
  let(:work) { DataSet.new }
  let(:depositor) { create(:user) }
  let(:depositor_ability) { ::Ability.new(depositor) }
  let(:env) { Hyrax::Actors::Environment.new(work, depositor_ability, {}) }

  # describe '#model_actor' do
  #   subject { described_class.new('Test').send(:model_actor, env) }
  #
  #   it "preserves the namespacing" do
  #     is_expected.to be_kind_of Hyrax::Actors::DataSetActor
  #   end
  # end
end
