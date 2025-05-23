require 'rails_helper'

RSpec.describe Hyrax::Actors::ApplyPermissionTemplateActor, skip: false do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.apply_permissions_template_actor_debug_verbose ).to eq( debug_verbose )
    end
  end

  describe 'all', skip: false do
    RSpec.shared_examples 'shared Hyrax::Actors::ApplyPermissionTemplateActor' do |dbg_verbose|
      subject { described_class }
      before do
        described_class.apply_permissions_template_actor_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose
      end
      after do
        described_class.apply_permissions_template_actor_debug_verbose = debug_verbose
      end
      context do
        let(:ability) { ::Ability.new(depositor) }
        let(:env) { Hyrax::Actors::Environment.new(work, ability, attributes) }
        let(:terminator) { Hyrax::Actors::Terminator.new }
        let(:depositor) { factory_bot_create_user(:user) }
        let(:work) do
          build(:data_set,
                user: depositor,
                edit_users: ['Kevin'],
                read_users: ['Taraji'])
        end
        let(:attributes) { { source_id: admin_set.id } }
        let(:admin_set) { create(:admin_set, with_permission_template: true) }
        let(:as_permission_template) { admin_set.permission_template }
        let(:collection) { create(:collection, with_permission_template: true) }
        let(:col_permission_template) { collection.permission_template }

        subject(:middleware) do
          stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
            middleware.use described_class
          end
          stack.build(terminator)
        end

        describe "create" do
          context "when source_id is blank" do
            let(:attributes) { { admin_set_id: '' } }

            it "returns true" do
              expect(middleware.create(env)).to be true
            end
          end

          context "when admin_set_id only is provided" do
            let(:attributes) { { admin_set_id: admin_set.id } }

            before do
              admin_set_access(as_permission_template)
              allow(terminator).to receive(:create).and_return(true)
            end

            it "adds the template users to the work" do
              expect(middleware.create(env)).to be true
              expect(work.edit_users).to match_array [depositor.user_key, 'Kevin', 'hannah a. smith']
              expect(work.edit_groups).to match_array ['librarians_as']
              expect(work.read_users).to match_array ['Taraji', 'gary a. stevens']
              expect(work.read_groups).to match_array ['readers_as']
            end
          end

          context "when admin_set_id and collection_id is provided" do
            let(:attributes) { { admin_set_id: admin_set.id, collection_id: collection.id } }

            before do
              admin_set_access(as_permission_template)
              collection_access(col_permission_template)
              allow(terminator).to receive(:create).and_return(true)
            end

            it "adds the template users to the work" do
              expect(middleware.create(env)).to be true
              expect(work.edit_users).to match_array [depositor.user_key, 'Kevin', 'hannah a. smith', 'joe conrad']
              expect(work.edit_groups).to match_array ['librarians_as', 'managers_c']
              expect(work.read_users).to match_array ['Taraji', 'gary a. stevens', 'carol cassidy']
              expect(work.read_groups).to match_array ['readers_as', 'viewers_c']
            end
          end

          def admin_set_access(permission_template) # rubocop:disable Metrics/MethodLength
            create(:permission_template_access,
                   :manage,
                   permission_template: permission_template,
                   agent_type: 'user',
                   agent_id: 'hannah a. smith')
            create(:permission_template_access,
                   :manage,
                   permission_template: permission_template,
                   agent_type: 'group',
                   agent_id: 'librarians_as')
            create(:permission_template_access,
                   :deposit,
                   permission_template: permission_template,
                   agent_type: 'user',
                   agent_id: 'mike a. steward')
            create(:permission_template_access,
                   :deposit,
                   permission_template: permission_template,
                   agent_type: 'group',
                   agent_id: 'staff_as')
            create(:permission_template_access,
                   :view,
                   permission_template: permission_template,
                   agent_type: 'user',
                   agent_id: 'gary a. stevens')
            create(:permission_template_access,
                   :view,
                   permission_template: permission_template,
                   agent_type: 'group',
                   agent_id: 'readers_as')
          end

          def collection_access(permission_template) # rubocop:disable Metrics/MethodLength
            create(:permission_template_access,
                   :manage,
                   permission_template: permission_template,
                   agent_type: 'user',
                   agent_id: "joe conrad")
            create(:permission_template_access,
                   :manage,
                   permission_template: permission_template,
                   agent_type: 'group',
                   agent_id: "managers_c")
            create(:permission_template_access,
                   :deposit,
                   permission_template: permission_template,
                   agent_type: 'user',
                   agent_id: "donny cartwright")
            create(:permission_template_access,
                   :deposit,
                   permission_template: permission_template,
                   agent_type: 'group',
                   agent_id: "depositors_c")
            create(:permission_template_access,
                   :view,
                   permission_template: permission_template,
                   agent_type: 'user',
                   agent_id: "carol cassidy")
            create(:permission_template_access,
                   :view,
                   permission_template: permission_template,
                   agent_type: 'group',
                   agent_id: "viewers_c")
          end
        end
      end
    end
    it_behaves_like 'shared Hyrax::Actors::ApplyPermissionTemplateActor', false
    it_behaves_like 'shared Hyrax::Actors::ApplyPermissionTemplateActor', true
  end

end
