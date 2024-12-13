require 'rails_helper'

RSpec.describe Hyrax::Actors::ApplyOrderActor, skip: false do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.apply_order_actor_debug_verbose ).to eq( debug_verbose )
    end
  end

  describe 'all', skip: false do
    RSpec.shared_examples 'shared Hyrax::Actors::ApplyOrderActor' do |dbg_verbose|
      subject { described_class }
      before do
        described_class.apply_order_actor_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose
      end
      after do
        described_class.apply_order_actor_debug_verbose = debug_verbose
      end
      context do
        let(:curation_concern) { create(:data_set_with_two_children,
                                        user: user,
                                        id: 'id321',
                                        title: ['test title'],
                                        creator: ["Dr. Author"],
                                        description: ["The Description"],
                                        methodology: ["The Methodology"],
                                        rights_license: "The Rights License",
                                        authoremail: "author@umich.edu" ) }
        let(:ability)    { ::Ability.new(user) }
        let(:user)       { factory_bot_create_user(:admin) }
        let(:terminator) { Hyrax::Actors::Terminator.new }
        let(:env)        { Hyrax::Actors::Environment.new(curation_concern, ability, attributes) }

        subject(:middleware) do
          stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
            middleware.use described_class
            middleware.use Hyrax::Actors::DataSetActor
          end
          stack.build(terminator)
        end

        describe '#update' do
          context 'with ordered_member_ids that are already associated with the parent' do
            let(:attributes) { { ordered_member_ids: ["BlahBlah1"] } }

            before do
              allow(terminator).to receive(:update).with(Hyrax::Actors::Environment).and_return(true)
              curation_concern.apply_depositor_metadata(user.user_key)
              curation_concern.save!
            end
            it "attaches the parent" do
              expect(subject.update(env)).to be true
            end
          end
        end

        describe '#update' do
          let(:user) { factory_bot_create_user(:admin) }
          let(:curation_concern) { create( :data_set_with_one_child,
                                           user: user,
                                           id: 'id321',
                                           title: ['test title'],
                                           creator: ["Dr. Author"],
                                           description: ["The Description"],
                                           methodology: ["The Methodology"],
                                           rights_license: "The Rights License",
                                           authoremail: "author@umich.edu" ) }
          let(:child) { FileSet.new }

          context 'with ordered_members_ids that arent associated with the curation concern yet.' do
            let(:attributes) { { ordered_member_ids: [child.id] } }
            let(:root_actor) { double }

            before do
              allow(terminator).to receive(:update).with(Hyrax::Actors::Environment).and_return(true)
              # TODO: This can be moved into the Factory
              child.title = ["Generic Title"]
              child.apply_depositor_metadata(user.user_key)
              child.save!
              curation_concern.apply_depositor_metadata(user.user_key)
              curation_concern.save!
            end

            it "attaches the parent" do
              expect(subject.update(env)).to be true
            end
          end

          context 'without an ordered_member_id that was associated with the curation concern' do
            let(:curation_concern) { create(:data_set_with_two_children, user: user) }
            let(:attributes) { { ordered_member_ids: ["BlahBlah2"] } }

            before do
              allow(terminator).to receive(:update).with(Hyrax::Actors::Environment).and_return(true)
              child.title = ["Generic Title"]
              child.apply_depositor_metadata(user.user_key)
              child.save!
              curation_concern.apply_depositor_metadata(user.user_key)
              curation_concern.save!
            end
            it "removes the first child" do
              expect(subject.update(env)).to be true
              expect(curation_concern.members.size).to eq(1)
              expect(curation_concern.ordered_member_ids.size).to eq(1)
            end
          end

          context 'with ordered_member_ids that include a work owned by a different user' do
            # set user not a non-admin for this test to ensure the actor disallows adding the child
            let(:user) { factory_bot_create_user(:user) }
            let(:other_user) { factory_bot_create_user(:user) }
            let(:child) { create(:data_set, user: other_user) }
            let(:attributes) { { ordered_member_ids: [child.id] } }

            before do
              allow(terminator).to receive(:update).with(Hyrax::Actors::Environment).and_return(true)
              curation_concern.apply_depositor_metadata(user.user_key)
              curation_concern.save!
            end

            it "does not attach the work" do
              expect(subject.update(env)).to be false
            end
          end
        end
      end
    end
    it_behaves_like 'shared Hyrax::Actors::ApplyOrderActor', false
    it_behaves_like 'shared Hyrax::Actors::ApplyOrderActor', true
  end

end
