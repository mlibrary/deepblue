# frozen_string_literal: true
# Updated: hyrax5
require 'rails_helper'
require 'cancan/matchers'

#hyrax5 - RSpec.describe Hyrax::Ability::AdminSetAbility do
RSpec.describe Hyrax::Ability, :clean_repo do
  subject(:ability) { Ability.new(current_user) }
  let(:admin) { factory_bot_create_user(:admin, email: 'admin@example.com') }
  let(:user) { factory_bot_create_user(:user, email: 'user@example.com') }
  let(:current_user) { user }

  #hyrax5 - context 'first' do
  #   let(:admin_set) { create(:admin_set, edit_users: [user], with_permission_template: true) }
  #
  #   context 'when user who created the admin set' do
  #     it 'allows the edit_users to edit and read' do
  #       is_expected.to be_able_to(:read, admin_set)
  #       is_expected.to be_able_to(:edit, admin_set)
  #     end
  #   end
  #
  #   context 'when admin user 1' do
  #     let(:current_user) { admin }
  #
  #     let(:user) { factory_bot_create_user(:admin) }
  #     let!(:solr_document) { SolrDocument.new(admin_set.to_solr) }
  #
  #     it 'allows all abilities' do # rubocop:disable RSpec/ExampleLength
  #       is_expected.to be_able_to(:manage, AdminSet)
  #       is_expected.to be_able_to(:manage_any, AdminSet)
  #       is_expected.to be_able_to(:create_any, AdminSet)
  #       is_expected.to be_able_to(:create, AdminSet)
  #       is_expected.to be_able_to(:view_admin_show_any, AdminSet)
  #       is_expected.to be_able_to(:edit, admin_set)
  #       is_expected.to be_able_to(:edit, solr_document) # defined in solr_document_ability.rb
  #       is_expected.to be_able_to(:update, admin_set)
  #       is_expected.to be_able_to(:update, solr_document) # defined in solr_document_ability.rb
  #       is_expected.to be_able_to(:destroy, admin_set)
  #       is_expected.to be_able_to(:destroy, solr_document) # defined in solr_document_ability.rb
  #       is_expected.to be_able_to(:deposit, admin_set)
  #       is_expected.to be_able_to(:deposit, solr_document)
  #       is_expected.to be_able_to(:view_admin_show, admin_set)
  #       is_expected.to be_able_to(:view_admin_show, solr_document)
  #       is_expected.to be_able_to(:read, admin_set) # admins can do everything
  #       is_expected.to be_able_to(:read, solr_document) # defined in solr_document_ability.rb
  #     end
  #   end
  # end

  context 'when admin user' do
    let(:current_user) { admin }

    context 'and admin set is an ActiveFedora::Base', :active_fedora do
      let(:admin_set) { FactoryBot.create(:adminset_lw, user: user, with_permission_template: true) }
      let!(:solr_document) { SolrDocument.new(admin_set.to_solr) }

      context 'for abilities open to admins' do
        it { is_expected.to be_able_to(:manage, AdminSet) }
        it { is_expected.to be_able_to(:manage_any, AdminSet) }
        it { is_expected.to be_able_to(:create_any, AdminSet) }
        it { is_expected.to be_able_to(:create, AdminSet) }
        it { is_expected.to be_able_to(:view_admin_show_any, AdminSet) }
        it { is_expected.to be_able_to(:edit, admin_set) }
        it { is_expected.to be_able_to(:edit, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.to be_able_to(:update, admin_set) }
        it { is_expected.to be_able_to(:update, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.to be_able_to(:destroy, admin_set) }
        it { is_expected.to be_able_to(:destroy, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.to be_able_to(:deposit, admin_set) }
        it { is_expected.to be_able_to(:deposit, solr_document) }
        it { is_expected.to be_able_to(:view_admin_show, admin_set) }
        it { is_expected.to be_able_to(:view_admin_show, solr_document) }
        it { is_expected.to be_able_to(:read, admin_set) }
        it { is_expected.to be_able_to(:read, solr_document) } # defined in solr_document_ability.rb
      end
    end

    context 'and admin set is a valkyrie resource' do
      let!(:admin_set) { FactoryBot.valkyrie_create(:hyrax_admin_set, user: user, with_permission_template: true) }
      let!(:solr_document) { SolrDocument.new(Hyrax::AdministrativeSetIndexer.new(resource: admin_set).to_solr) }

      context 'for abilities open to admins' do
        it { is_expected.to be_able_to(:manage, Hyrax::AdministrativeSet) }
        it { is_expected.to be_able_to(:manage_any, Hyrax::AdministrativeSet) }
        it { is_expected.to be_able_to(:create_any, Hyrax::AdministrativeSet) }
        it { is_expected.to be_able_to(:create, Hyrax::AdministrativeSet) }
        it { is_expected.to be_able_to(:view_admin_show_any, Hyrax::AdministrativeSet) }
        it { is_expected.to be_able_to(:edit, admin_set) }
        it { is_expected.to be_able_to(:edit, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.to be_able_to(:update, admin_set) }
        it { is_expected.to be_able_to(:update, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.to be_able_to(:destroy, admin_set) }
        it { is_expected.to be_able_to(:destroy, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.to be_able_to(:deposit, admin_set) }
        it { is_expected.to be_able_to(:deposit, solr_document) }
        it { is_expected.to be_able_to(:view_admin_show, admin_set) }
        it { is_expected.to be_able_to(:view_admin_show, solr_document) }
        it { is_expected.to be_able_to(:read, admin_set) }
        it { is_expected.to be_able_to(:read, solr_document) } # defined in solr_document_ability.rb
      end
    end
  end

  #hyrax5 - context 'when admin set manager 1' do
  #   let!(:admin_set) { create(:admin_set, id: 'as_mu', with_permission_template: true) }
  #   let!(:solr_document) { SolrDocument.new(admin_set.to_solr) }
  #
  #   before do
  #     create(:permission_template_access,
  #            :manage,
  #            permission_template: admin_set.permission_template,
  #            agent_type: 'user',
  #            agent_id: user.user_key)
  #     admin_set.reset_access_controls!
  #   end
  #
  #   it 'allows most abilities' do # rubocop:disable RSpec/ExampleLength
  #     is_expected.to be_able_to(:manage_any, AdminSet)
  #     is_expected.to be_able_to(:view_admin_show_any, AdminSet)
  #     is_expected.to be_able_to(:edit, admin_set) # defined in solr_document_ability.rb
  #     is_expected.to be_able_to(:edit, solr_document)
  #     is_expected.to be_able_to(:update, admin_set) # defined in solr_document_ability.rb
  #     is_expected.to be_able_to(:update, solr_document)
  #     is_expected.to be_able_to(:destroy, admin_set) # defined in solr_document_ability.rb
  #     is_expected.to be_able_to(:destroy, solr_document)
  #     is_expected.to be_able_to(:deposit, admin_set)
  #     is_expected.to be_able_to(:deposit, solr_document)
  #     is_expected.to be_able_to(:view_admin_show, admin_set)
  #     is_expected.to be_able_to(:view_admin_show, solr_document)
  #     is_expected.to be_able_to(:read, admin_set) # edit access grants read and write
  #     is_expected.to be_able_to(:read, solr_document) # edit access grants read and write # defined in solr_document_ability.rb
  #   end
  #
  #   it 'denies manage ability' do
  #     is_expected.not_to be_able_to(:manage, AdminSet)
  #     is_expected.not_to be_able_to(:create_any, AdminSet) # granted by collection type, not collection
  #     is_expected.not_to be_able_to(:create, AdminSet)
  #   end
  # end

  context 'when admin set manager' do
    let(:current_user) { manager }
    let(:manager) { factory_bot_create_user(:user, email: 'manager@example.com') }

    context 'and admin set is an ActiveFedora::Base', :active_fedora do
      let!(:admin_set) { FactoryBot.create(:adminset_lw, id: 'as_mu', user: user, with_permission_template: true) }
      let!(:solr_document) { SolrDocument.new(admin_set.to_solr) }

      before do
        FactoryBot.create(:permission_template_access,
                          :manage,
                          permission_template: admin_set.permission_template,
                          agent_type: 'user',
                          agent_id: manager.user_key)
        admin_set.permission_template.reset_access_controls_for(collection: admin_set)
      end

      context 'for abilities open to managers' do
        it { is_expected.to be_able_to(:manage_any, AdminSet) }
        it { is_expected.to be_able_to(:view_admin_show_any, AdminSet) }
        it { is_expected.to be_able_to(:edit, admin_set) }
        it { is_expected.to be_able_to(:edit, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.to be_able_to(:update, admin_set) }
        it { is_expected.to be_able_to(:update, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.to be_able_to(:destroy, admin_set) }
        it { is_expected.to be_able_to(:destroy, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.to be_able_to(:deposit, admin_set) }
        it { is_expected.to be_able_to(:deposit, solr_document) }
        it { is_expected.to be_able_to(:view_admin_show, admin_set) }
        it { is_expected.to be_able_to(:view_admin_show, solr_document) }
        it { is_expected.to be_able_to(:read, admin_set) }
        it { is_expected.to be_able_to(:read, solr_document) } # defined in solr_document_ability.rb
      end

      context 'for abilities NOT open to managers' do
        it { is_expected.not_to be_able_to(:manage, AdminSet) }
        it { is_expected.not_to be_able_to(:create_any, AdminSet) } # granted by collection type, not collection
        it { is_expected.not_to be_able_to(:create, AdminSet) }
      end
    end

    context 'and admin set is a valkyrie resource' do
      let!(:admin_set) { FactoryBot.valkyrie_create(:hyrax_admin_set, user: user, access_grants: grants, with_permission_template: true) }
      let!(:solr_document) { SolrDocument.new(Hyrax::AdministrativeSetIndexer.new(resource: admin_set).to_solr) }

      let(:grants) do
        [
          {
            agent_type: Hyrax::PermissionTemplateAccess::USER,
            agent_id: manager.user_key,
            access: Hyrax::PermissionTemplateAccess::MANAGE
          }
        ]
      end

      context 'for abilities open to managers' do
        it { is_expected.to be_able_to(:manage_any, Hyrax::AdministrativeSet) }
        it { is_expected.to be_able_to(:view_admin_show_any, Hyrax::AdministrativeSet) }
        it { is_expected.to be_able_to(:edit, admin_set) }
        it { is_expected.to be_able_to(:edit, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.to be_able_to(:update, admin_set) }
        it { is_expected.to be_able_to(:update, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.to be_able_to(:destroy, admin_set) }
        it { is_expected.to be_able_to(:destroy, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.to be_able_to(:deposit, admin_set) }
        it { is_expected.to be_able_to(:deposit, solr_document) }
        it { is_expected.to be_able_to(:view_admin_show, admin_set) }
        it { is_expected.to be_able_to(:view_admin_show, solr_document) }
        it { is_expected.to be_able_to(:read, admin_set) }
        it { is_expected.to be_able_to(:read, solr_document) } # defined in solr_document_ability.rb
      end

      context 'for abilities NOT open to managers' do
        it { is_expected.not_to be_able_to(:manage, Hyrax::AdministrativeSet) }
        it { is_expected.not_to be_able_to(:create_any, Hyrax::AdministrativeSet) } # granted by collection type, not collection
        it { is_expected.not_to be_able_to(:create, Hyrax::AdministrativeSet) }
      end
    end
  end

  #hyrax5 - context 'when admin set depositor 1' do
  #   let!(:admin_set) { create(:admin_set, id: 'as_du', with_permission_template: true) }
  #   let!(:solr_document) { SolrDocument.new(admin_set.to_solr) }
  #
  #   before do
  #     create(:permission_template_access,
  #            :deposit,
  #            permission_template: admin_set.permission_template,
  #            agent_type: 'user',
  #            agent_id: user.user_key)
  #     admin_set.reset_access_controls!
  #   end
  #
  #   it 'allows deposit related abilities' do
  #     is_expected.to be_able_to(:view_admin_show_any, AdminSet)
  #     is_expected.to be_able_to(:deposit, admin_set)
  #     is_expected.to be_able_to(:deposit, solr_document)
  #     is_expected.to be_able_to(:view_admin_show, admin_set)
  #     is_expected.to be_able_to(:view_admin_show, solr_document)
  #   end
  #
  #   it 'denies non-deposit related abilities' do # rubocop:disable RSpec/ExampleLength
  #     is_expected.not_to be_able_to(:manage, AdminSet)
  #     is_expected.not_to be_able_to(:manage_any, AdminSet)
  #     is_expected.not_to be_able_to(:create_any, AdminSet) # granted by collection type, not collection
  #     is_expected.not_to be_able_to(:create, AdminSet)
  #     is_expected.not_to be_able_to(:edit, admin_set)
  #     is_expected.not_to be_able_to(:edit, solr_document) # defined in solr_document_ability.rb
  #     is_expected.not_to be_able_to(:update, admin_set)
  #     is_expected.not_to be_able_to(:update, solr_document) # defined in solr_document_ability.rb
  #     is_expected.not_to be_able_to(:destroy, admin_set)
  #     is_expected.not_to be_able_to(:destroy, solr_document) # defined in solr_document_ability.rb
  #     is_expected.not_to be_able_to(:read, admin_set) # no public page for admin sets
  #     is_expected.not_to be_able_to(:read, solr_document) # defined in solr_document_ability.rb
  #   end
  # end

  context 'when admin set depositor' do
    let(:current_user) { depositor }
    let(:depositor) { factory_bot_create_user(:user, email: 'depositor@example.com') }

    context 'and admin set is an ActiveFedora::Base', :active_fedora do
      let!(:admin_set) { create(:adminset_lw, id: 'as_du', user: user, with_permission_template: true) }
      let!(:solr_document) { SolrDocument.new(admin_set.to_solr) }

      before do
        create(:permission_template_access,
               :deposit,
               permission_template: admin_set.permission_template,
               agent_type: 'user',
               agent_id: depositor.user_key)
        admin_set.permission_template.reset_access_controls_for(collection: admin_set)
      end

      context 'for abilities open to depositor' do
        it { is_expected.to be_able_to(:view_admin_show_any, AdminSet) }
        it { is_expected.to be_able_to(:deposit, admin_set) }
        it { is_expected.to be_able_to(:deposit, solr_document) }
        it { is_expected.to be_able_to(:view_admin_show, admin_set) }
        it { is_expected.to be_able_to(:view_admin_show, solr_document) }

        # There isn't a public show page for admin_sets, but since the user has
        # permission to view the admin show page, they have permission to view
        # the non-existent public show page.
        it { is_expected.to be_able_to(:read, admin_set) }
        it { is_expected.to be_able_to(:read, solr_document) } # defined in solr_document_ability.rb
      end

      context 'for abilities NOT open to depositor' do
        it { is_expected.not_to be_able_to(:manage, AdminSet) }
        it { is_expected.not_to be_able_to(:manage_any, AdminSet) }
        it { is_expected.not_to be_able_to(:create_any, AdminSet) } # granted by collection type, not collection
        it { is_expected.not_to be_able_to(:create, AdminSet) }
        it { is_expected.not_to be_able_to(:edit, admin_set) }
        it { is_expected.not_to be_able_to(:edit, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:update, admin_set) }
        it { is_expected.not_to be_able_to(:update, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:destroy, admin_set) }
        it { is_expected.not_to be_able_to(:destroy, solr_document) } # defined in solr_document_ability.rb
      end
    end

    context 'and admin set is a valkyrie resource' do
      let!(:admin_set) { FactoryBot.valkyrie_create(:hyrax_admin_set, user: user, access_grants: grants, with_permission_template: true) }
      let!(:solr_document) { SolrDocument.new(Hyrax::AdministrativeSetIndexer.new(resource: admin_set).to_solr) }

      let(:grants) do
        [
          {
            agent_type: Hyrax::PermissionTemplateAccess::USER,
            agent_id: depositor.user_key,
            access: Hyrax::PermissionTemplateAccess::DEPOSIT
          }
        ]
      end

      context 'for abilities open to depositor' do
        it { is_expected.to be_able_to(:view_admin_show_any, Hyrax::AdministrativeSet) }
        it { is_expected.to be_able_to(:deposit, admin_set) }
        it { is_expected.to be_able_to(:deposit, solr_document) }
        it { is_expected.to be_able_to(:view_admin_show, admin_set) }
        it { is_expected.to be_able_to(:view_admin_show, solr_document) }

        # There isn't a public show page for admin_sets, but since the user has
        # permission to view the admin show page, they have permission to view
        # the non-existent public show page.
        it { is_expected.to be_able_to(:read, admin_set) }
        it { is_expected.to be_able_to(:read, solr_document) } # defined in solr_document_ability.rb
      end

      context 'for abilities NOT open to depositor' do
        it { is_expected.not_to be_able_to(:manage, Hyrax::AdministrativeSet) }
        it { is_expected.not_to be_able_to(:manage_any, Hyrax::AdministrativeSet) }
        it { is_expected.not_to be_able_to(:create_any, Hyrax::AdministrativeSet) } # granted by collection type, not collection
        it { is_expected.not_to be_able_to(:create, Hyrax::AdministrativeSet) }
        it { is_expected.not_to be_able_to(:edit, admin_set) }
        it { is_expected.not_to be_able_to(:edit, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:update, admin_set) }
        it { is_expected.not_to be_able_to(:update, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:destroy, admin_set) }
        it { is_expected.not_to be_able_to(:destroy, solr_document) } # defined in solr_document_ability.rb
      end
    end
  end

  #hyrax5 - context 'when admin set viewer 1' do
  #   let!(:admin_set) { create(:admin_set, id: 'as_vu', with_permission_template: true) }
  #   let!(:solr_document) { SolrDocument.new(admin_set.to_solr) }
  #
  #   before do
  #     create(:permission_template_access,
  #            :view,
  #            permission_template: admin_set.permission_template,
  #            agent_type: 'user',
  #            agent_id: user.user_key)
  #     admin_set.reset_access_controls!
  #   end
  #
  #   it 'allows viewing only ability' do
  #     is_expected.to be_able_to(:view_admin_show_any, AdminSet)
  #     is_expected.to be_able_to(:view_admin_show, admin_set)
  #   end
  #
  #   it 'denies most abilities' do # rubocop:disable RSpec/ExampleLength
  #     is_expected.not_to be_able_to(:manage, AdminSet)
  #     is_expected.not_to be_able_to(:manage_any, AdminSet)
  #     is_expected.not_to be_able_to(:create_any, AdminSet) # granted by collection type, not collection
  #     is_expected.not_to be_able_to(:create, AdminSet)
  #     is_expected.not_to be_able_to(:edit, admin_set)
  #     is_expected.not_to be_able_to(:edit, solr_document) # defined in solr_document_ability.rb
  #     is_expected.not_to be_able_to(:update, admin_set)
  #     is_expected.not_to be_able_to(:update, solr_document) # defined in solr_document_ability.rb
  #     is_expected.not_to be_able_to(:destroy, admin_set)
  #     is_expected.not_to be_able_to(:destroy, solr_document) # defined in solr_document_ability.rb
  #     is_expected.not_to be_able_to(:deposit, admin_set)
  #     is_expected.not_to be_able_to(:deposit, solr_document)
  #     is_expected.not_to be_able_to(:read, admin_set) # no public page for admin sets
  #     is_expected.not_to be_able_to(:read, solr_document) # defined in solr_document_ability.rb
  #   end
  # end

  context 'when admin set viewer' do
    let(:current_user) { viewer }
    let(:viewer) { factory_bot_create_user(:user, email: 'viewer@example.com') }

    context 'and admin set is an ActiveFedora::Base', :active_fedora do
      let!(:admin_set) { create(:adminset_lw, id: 'as_vu', user: user, with_permission_template: true) }
      let!(:solr_document) { SolrDocument.new(admin_set.to_solr) }

      before do
        create(:permission_template_access,
               :view,
               permission_template: admin_set.permission_template,
               agent_type: 'user',
               agent_id: viewer.user_key)
        admin_set.permission_template.reset_access_controls_for(collection: admin_set)
      end

      context 'for abilities open to viewer' do
        it { is_expected.to be_able_to(:view_admin_show_any, AdminSet) }
        it { is_expected.to be_able_to(:view_admin_show, admin_set) }

        # There isn't a public show page for admin_sets, but since the user has
        # permission to view the admin show page, they have permission to view
        # the non-existent public show page.
        it { is_expected.to be_able_to(:read, admin_set) }
        it { is_expected.to be_able_to(:read, solr_document) } # defined in solr_document_ability.rb
      end

      context 'for abilities NOT open to viewer' do
        it { is_expected.not_to be_able_to(:manage, AdminSet) }
        it { is_expected.not_to be_able_to(:manage_any, AdminSet) }
        it { is_expected.not_to be_able_to(:create_any, AdminSet) } # granted by collection type, not collection
        it { is_expected.not_to be_able_to(:create, AdminSet) }
        it { is_expected.not_to be_able_to(:edit, admin_set) }
        it { is_expected.not_to be_able_to(:edit, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:update, admin_set) }
        it { is_expected.not_to be_able_to(:update, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:destroy, admin_set) }
        it { is_expected.not_to be_able_to(:destroy, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:deposit, admin_set) }
        it { is_expected.not_to be_able_to(:deposit, solr_document) }
      end
    end

    context 'and admin set is a valkyrie resource' do
      let!(:admin_set) { FactoryBot.valkyrie_create(:hyrax_admin_set, user: user, access_grants: grants, with_permission_template: true) }
      let!(:solr_document) { SolrDocument.new(Hyrax::AdministrativeSetIndexer.new(resource: admin_set).to_solr) }

      let(:grants) do
        [
          {
            agent_type: Hyrax::PermissionTemplateAccess::USER,
            agent_id: viewer.user_key,
            access: Hyrax::PermissionTemplateAccess::VIEW
          }
        ]
      end

      context 'for abilities open to viewer' do
        it { is_expected.to be_able_to(:view_admin_show_any, Hyrax::AdministrativeSet) }
        it { is_expected.to be_able_to(:view_admin_show, admin_set) }

        # There isn't a public show page for admin_sets, but since the user has
        # permission to view the admin show page, they have permission to view
        # the non-existent public show page.
        it { is_expected.to be_able_to(:read, admin_set) } # no public page for admin sets
        it { is_expected.to be_able_to(:read, solr_document) }
      end

      context 'for abilities NOT open to viewer' do
        it { is_expected.not_to be_able_to(:manage, Hyrax::AdministrativeSet) }
        it { is_expected.not_to be_able_to(:manage_any, Hyrax::AdministrativeSet) }
        it { is_expected.not_to be_able_to(:create_any, Hyrax::AdministrativeSet) } # granted by collection type, not collection
        it { is_expected.not_to be_able_to(:create, Hyrax::AdministrativeSet) }
        it { is_expected.not_to be_able_to(:edit, admin_set) }
        it { is_expected.not_to be_able_to(:edit, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:update, admin_set) }
        it { is_expected.not_to be_able_to(:update, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:destroy, admin_set) }
        it { is_expected.not_to be_able_to(:destroy, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:deposit, admin_set) }
        it { is_expected.not_to be_able_to(:deposit, solr_document) }
      end
    end
  end

  context 'when user has no special access 1' do
    let(:admin_set) { create(:admin_set, id: 'as', with_permission_template: true) }
    let!(:solr_document) { SolrDocument.new(admin_set.to_solr) }

    it 'denies all abilities' do # rubocop:disable RSpec/ExampleLength
      is_expected.not_to be_able_to(:manage, AdminSet)
      is_expected.not_to be_able_to(:manage_any, AdminSet)
      is_expected.not_to be_able_to(:create_any, AdminSet) # granted by collection type, not collection
      is_expected.not_to be_able_to(:create, AdminSet)
      is_expected.not_to be_able_to(:view_admin_show_any, AdminSet)
      is_expected.not_to be_able_to(:edit, admin_set)
      is_expected.not_to be_able_to(:edit, solr_document) # defined in solr_document_ability.rb
      is_expected.not_to be_able_to(:update, admin_set)
      is_expected.not_to be_able_to(:update, solr_document) # defined in solr_document_ability.rb
      is_expected.not_to be_able_to(:destroy, admin_set)
      is_expected.not_to be_able_to(:destroy, solr_document) # defined in solr_document_ability.rb
      is_expected.not_to be_able_to(:deposit, admin_set)
      is_expected.not_to be_able_to(:deposit, solr_document) # defined in solr_document_ability.rb
      is_expected.not_to be_able_to(:view_admin_show, admin_set)
      is_expected.not_to be_able_to(:view_admin_show, solr_document)
      is_expected.not_to be_able_to(:read, admin_set) # no public page for admin sets
      is_expected.not_to be_able_to(:read, solr_document) # defined in solr_document_ability.rb
    end
  end

  context 'when user has no special access' do
    let(:current_user) { other_user }
    let(:other_user) { factory_bot_create_user(:user, email: 'other_user@example.com') }

    context 'and admin set is an ActiveFedora::Base', :active_fedora do
      let(:admin_set) { FactoryBot.create(:adminset_lw, id: 'as', user: user, with_permission_template: true) }
      let!(:solr_document) { SolrDocument.new(admin_set.to_solr) }

      context 'for abilities NOT open to general user' do
        it { is_expected.not_to be_able_to(:manage, AdminSet) }
        it { is_expected.not_to be_able_to(:manage_any, AdminSet) }
        it { is_expected.not_to be_able_to(:create_any, AdminSet) } # granted by collection type, not collection
        it { is_expected.not_to be_able_to(:create, AdminSet) }
        it { is_expected.not_to be_able_to(:view_admin_show_any, AdminSet) }
        it { is_expected.not_to be_able_to(:edit, admin_set) }
        it { is_expected.not_to be_able_to(:edit, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:update, admin_set) }
        it { is_expected.not_to be_able_to(:update, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:destroy, admin_set) }
        it { is_expected.not_to be_able_to(:destroy, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:deposit, admin_set) }
        it { is_expected.not_to be_able_to(:deposit, solr_document) }
        it { is_expected.not_to be_able_to(:view_admin_show, admin_set) }
        it { is_expected.not_to be_able_to(:view_admin_show, solr_document) }
        it { is_expected.not_to be_able_to(:read, admin_set) }
        it { is_expected.not_to be_able_to(:read, solr_document) } # defined in solr_document_ability.rb
      end
    end

    context 'and admin set is a valkyrie resource' do
      let!(:admin_set) { FactoryBot.valkyrie_create(:hyrax_admin_set, user: user, with_permission_template: true) }
      let!(:solr_document) { SolrDocument.new(Hyrax::AdministrativeSetIndexer.new(resource: admin_set).to_solr) }

      context 'for abilities NOT open to general user' do
        it { is_expected.not_to be_able_to(:manage, Hyrax::AdministrativeSet) }
        it { is_expected.not_to be_able_to(:manage_any, Hyrax::AdministrativeSet) }
        it { is_expected.not_to be_able_to(:create_any, Hyrax::AdministrativeSet) } # granted by collection type, not collection
        it { is_expected.not_to be_able_to(:create, Hyrax::AdministrativeSet) }
        it { is_expected.not_to be_able_to(:view_admin_show_any, Hyrax::AdministrativeSet) }
        it { is_expected.not_to be_able_to(:edit, admin_set) }
        it { is_expected.not_to be_able_to(:edit, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:update, admin_set) }
        it { is_expected.not_to be_able_to(:update, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:destroy, admin_set) }
        it { is_expected.not_to be_able_to(:destroy, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:deposit, admin_set) }
        it { is_expected.not_to be_able_to(:deposit, solr_document) }
        it { is_expected.not_to be_able_to(:view_admin_show, admin_set) }
        it { is_expected.not_to be_able_to(:view_admin_show, solr_document) }
        it { is_expected.not_to be_able_to(:read, admin_set) }
        it { is_expected.not_to be_able_to(:read, solr_document) } # defined in solr_document_ability.rb
      end
    end
  end
end
