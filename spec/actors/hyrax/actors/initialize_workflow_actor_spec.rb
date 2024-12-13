require 'rails_helper'

RSpec.describe Hyrax::Actors::InitializeWorkflowActor, skip: false do
  let(:user) { factory_bot_create_user(:user) }
  let(:ability) { ::Ability.new(user) }
  let(:curation_concern) { build(:data_set) }
  let(:attributes) { { title: ['test'] } }

  let(:terminator) { Hyrax::Actors::Terminator.new }
  let(:env) { Hyrax::Actors::Environment.new(curation_concern, ability, attributes) }

  subject(:middleware) do
    stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
      middleware.use described_class
      middleware.use Hyrax::Actors::DataSetActor
    end
    stack.build(terminator)
  end

  describe 'the next actor' do
    it 'passes the attributes on' do
      expect(terminator).to receive(:create).with(Hyrax::Actors::Environment)
      subject.create(env)
    end
  end

  describe 'create' do
    let(:curation_concern) { build(:data_set, admin_set: admin_set) }
    let!(:admin_set) { create(:admin_set, with_permission_template: { with_workflows: true }) }

    it 'creates an entity' do
      expect do
        expect(subject.create(env)).to be true
      end.to change { Sipity::Entity.count }.by(1)
    end
  end
end
