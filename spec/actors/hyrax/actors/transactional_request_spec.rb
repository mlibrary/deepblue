require 'rails_helper'

RSpec.describe Hyrax::Actors::TransactionalRequest, skip: true do
  let(:bad_actor) do
    Class.new(Hyrax::Actors::AbstractActor) do
      def create(attributes)
        next_actor.create(attributes) && raise('boom')
      end
    end
  end

  let(:good_actor) do
    Class.new(Hyrax::Actors::AbstractActor) do
      def create(_attributes)
        FactoryBot.create(:user)
      end
    end
  end

  let(:ability) { ::Ability.new(depositor) }
  let(:env) { Hyrax::Actors::Environment.new(work, ability, attributes) }
  let(:terminator) { Hyrax::Actors::Terminator.new }
  let(:depositor) { instance_double(User, new_record?: true, guest?: true, id: nil, user_key: nil) }
  let(:work) { double(:work) }

  subject(:middleware) do
    stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
      middleware.use described_class
      middleware.use bad_actor
      middleware.use good_actor
    end
    stack.build(terminator)
  end

  describe "create" do
    let(:attributes) { {} }

    subject { middleware.create(env) }

    # Note that this test changed behavior with the
    # backport of https://github.com/samvera/hyrax/pull/3482
    it "does NOT roll back any database changes" do
      expect do
        expect { subject }.to raise_error 'boom'
      end.to change { User.count } # Note the above good actor creates a user
    end
  end
end
