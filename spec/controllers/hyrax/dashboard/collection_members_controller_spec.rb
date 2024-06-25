# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::Dashboard::CollectionMembersController, :clean_repo, skip: false do

  include Devise::Test::ControllerHelpers
  routes { Hyrax::Engine.routes }

  let(:user) { FactoryBot.create(:user) }
  let(:other) { create(:user) }

  let(:work_1_own) { create(:work, id: 'work-1-own', title: ['First of the Assets'], user: user) }
  let(:work_2_own) { create(:work, id: 'work-2-own', title: ['Second of the Assets'], user: user) }
  let(:work_3_own) { create(:work, id: 'work-3-own', title: ['Third of the Assets'], user: user) }
  let(:work_4_edit) { create(:work, id: 'work-4-edit', title: ["Other's work with edit access"], user: other, edit_users: [user]) }
  let(:work_5_read) { create(:work, id: 'work-5-read', title: ["Other's work with read access"], user: other, read_users: [user]) }
  let(:work_6_noaccess) { create(:work, id: 'work-6-no_access', title: ["Other's work with no access"], user: other) }

  let(:coll_1_own) { create(:private_collection_lw, id: 'col-1-own', title: ['User created'], user: user, with_permission_template: true) }
  let(:coll_2_mgr) do
    create(:private_collection_lw, id: 'col-2-mgr', title: ['User has manage access'], user: other,
                                   with_permission_template: { manage_users: [user] })
  end
  let(:coll_3_dep) do
    create(:private_collection_lw, id: 'col-3-dep', title: ['User has deposit access'], user: other,
                                   with_permission_template: { deposit_users: [user] })
  end
  let(:coll_4_view) do
    create(:private_collection_lw, id: 'col-4-dep', title: ['User has view access'], user: other,
                                   with_permission_template: { view_users: [user] })
  end
  let(:coll_5_noaccess) do
    create(:private_collection_lw, id: 'col-5-no_access', title: ['Other user created'],
                                   user: other, with_permission_template: true)
  end

  before { sign_in(user) }

  describe '#update_members' do
    let(:owned_work_1) { FactoryBot.create(:work, user: user) }
    let(:owned_work_2) { FactoryBot.create(:work, user: user) }
    let(:owned_work_3) { FactoryBot.create(:work, user: user) }
    let(:private_work) { FactoryBot.valkyrie_create(:hyrax_work) }

    let(:queries) { Hyrax.custom_queries }

    let(:editable_work) do
      FactoryBot.valkyrie_create(:hyrax_work, edit_users: [user])
    end

    let(:readable_work) do
      FactoryBot.valkyrie_create(:hyrax_work, read_users: [user])
    end

    let(:owned_collection) do
      FactoryBot.create(:private_collection_lw,
                        user: user,
                        with_permission_template: true)
    end

    let(:managed_collection) do
      FactoryBot.create(:private_collection_lw,
                        with_permission_template: { manage_users: [user] })
    end

    let(:depositable_collection) do
      FactoryBot.create(:private_collection_lw,
                        with_permission_template: { deposit_users: [user] })
    end

    let(:viewable_collection) do
      FactoryBot.valkyrie_create(:hyrax_collection, read_users: [user])
    end

    let(:private_collection) do
      FactoryBot.valkyrie_create(:hyrax_collection, with_permission_template: true)
    end

    let(:parameters) do
      { id: collection,
        collection: { members: 'add' },
        batch_document_ids: members_to_add.map(&:id) }
    end

    context 'when user created the collection' do
      let(:collection) { owned_collection }

      before do
        [owned_work_1, owned_work_2].each do |asset|
          asset.member_of_collections << collection
          asset.save!
        end
      end

      context 'and user created the work' do
        let(:members_to_add) { [owned_work_3] }

        it 'adds members to the collection' do
          expect { post(:update_members, params: parameters) }
            .to change { queries.find_members_of(collection: collection.valkyrie_resource).map(&:id) }
            .from(contain_exactly(owned_work_1.id, owned_work_2.id))
            .to contain_exactly(owned_work_1.id, owned_work_2.id, owned_work_3.id)
        end

        it 'redirects to dashboard collection show' do
          post :update_members, params: parameters

          expect(response)
            .to redirect_to routes.url_helpers.dashboard_collection_path(collection, locale: 'en')
        end
      end

      context 'and user has edit access to works' do
        let(:members_to_add) { [editable_work] }

        it 'adds members to the collection' do
          expect { post(:update_members, params: parameters) }
            .to change { queries.find_members_of(collection: collection.valkyrie_resource).map(&:id) }
            .from(contain_exactly(owned_work_1.id, owned_work_2.id))
            .to contain_exactly(owned_work_1.id, owned_work_2.id, editable_work.id)
        end
      end

      context 'and user has read access to works' do
        let(:members_to_add) { [readable_work] }

        it 'adds members to the collection' do
          expect { post(:update_members, params: parameters) }
            .to change { queries.find_members_of(collection: collection.valkyrie_resource).map(&:id) }
            .from(contain_exactly(owned_work_1.id, owned_work_2.id))
            .to contain_exactly(owned_work_1.id, owned_work_2.id, readable_work.id)
        end
      end

      context 'and user has no access to a some works' do
        let(:members_to_add) { [owned_work_3, private_work] }

        it 'adds only members with read access' do
          expect { post :update_members, params: parameters }
            .to change { queries.find_members_of(collection: collection.valkyrie_resource).map(&:id) }
                  .from(contain_exactly(owned_work_1.id, owned_work_2.id))
                  .to contain_exactly(owned_work_1.id, owned_work_2.id, owned_work_3.id)
        end
      end

      context 'and user has no access to selected works' do
        let(:members_to_add) { [private_work] }

        it 'does not change membership' do
          expect { post(:update_members, params: parameters) }
            .not_to change { queries.find_members_of(collection: collection.valkyrie_resource).count }

          expect(flash[:alert])
            .to eq 'You do not have sufficient privileges to any of the selected members'
        end

        it 'flashes an error' do
          post :update_members, params: parameters

          expect(flash[:alert])
            .to eq 'You do not have sufficient privileges to any of the selected members'
        end
      end

      context 'and user adds a subcollection' do
        let(:parent_collection) { create(:private_collection_lw, id: 'pcol', title: ['User created another'], user: user, with_permission_template: true) }

        it 'adds collection user created' do
          expect do
            post :update_members, params: { id: parent_collection,
                                            collection: { members: 'add' },
                                            batch_document_ids: [coll_1_own.id] }
          end.to change { parent_collection.reload.member_objects.size }.by(1)
          expect(response).to redirect_to routes.url_helpers.dashboard_collection_path(parent_collection, locale: 'en')
          expect(parent_collection.member_objects).to match_array [coll_1_own]
        end

        it 'adds collection with manage access' do
          expect do
            post :update_members, params: { id: parent_collection,
                                            collection: { members: 'add' },
                                            batch_document_ids: [coll_2_mgr.id] }
          end.to change { parent_collection.reload.member_objects.size }.by(1)
          expect(response).to redirect_to routes.url_helpers.dashboard_collection_path(parent_collection, locale: 'en')
          expect(parent_collection.member_objects).to match_array [coll_2_mgr]
        end

        it 'adds collection with deposit access' do
          expect do
            post :update_members, params: { id: parent_collection,
                                            collection: { members: 'add' },
                                            batch_document_ids: [coll_3_dep.id] }
          end.to change { parent_collection.reload.member_objects.size }.by(1)
          expect(response).to redirect_to routes.url_helpers.dashboard_collection_path(parent_collection, locale: 'en')
          expect(parent_collection.member_objects).to match_array [coll_3_dep]
        end

        it 'adds collection with view access' do
          expect do
            post :update_members, params: { id: parent_collection,
                                            collection: { members: 'add' },
                                            batch_document_ids: [coll_4_view.id] }
          end.to change { parent_collection.reload.member_objects.size }.by(1)
          expect(response).to redirect_to routes.url_helpers.dashboard_collection_path(parent_collection, locale: 'en')
          expect(parent_collection.member_objects).to match_array [coll_4_view]
        end

        it 'displays error message for collection with no access' do
          expect do
            post :update_members, params: { id: parent_collection,
                                            collection: { members: 'add' },
                                            batch_document_ids: [coll_5_noaccess.id] }
          end.to change { parent_collection.reload.member_objects.size }.by(0)
          expect(flash[:alert]).to eq 'You do not have sufficient privileges to any of the selected members'
          expect(response).to redirect_to routes.url_helpers.dashboard_collections_path(locale: 'en')
          expect(parent_collection.member_objects).to match_array []
        end
      end
    end

    context 'when user is manager of the collection' do
      before do
        sign_in user
        [work_1_own, work_2_own].each do |asset|
          asset.member_of_collections << coll_2_mgr
          asset.save!
        end
      end

      context 'and user created the work' do
        it 'adds members to the collection' do
          expect do
            post :update_members, params: { id: coll_2_mgr,
                                            collection: { members: 'add' },
                                            batch_document_ids: [work_3_own.id] }
          end.to change { coll_2_mgr.reload.member_objects.size }.by(1)
          expect(response).to redirect_to routes.url_helpers.dashboard_collection_path(coll_2_mgr, locale: 'en')
          expect(coll_2_mgr.member_objects).to match_array [work_1_own, work_2_own, work_3_own]
        end
      end

      context 'and user has edit access to works' do
        it 'adds members to the collection' do
          expect do
            post :update_members, params: { id: coll_2_mgr,
                                            collection: { members: 'add' },
                                            batch_document_ids: [work_4_edit.id] }
          end.to change { coll_2_mgr.reload.member_objects.size }.by(1)
          expect(response).to redirect_to routes.url_helpers.dashboard_collection_path(coll_2_mgr, locale: 'en')
          expect(coll_2_mgr.member_objects).to match_array [work_1_own, work_2_own, work_4_edit]
        end
      end

      context 'and user has read access to works' do
        it 'adds members to the collection' do
          expect do
            post :update_members, params: { id: coll_2_mgr,
                                            collection: { members: 'add' },
                                            batch_document_ids: [work_5_read.id] }
          end.to change { coll_2_mgr.reload.member_objects.size }.by(1)
          expect(response).to redirect_to routes.url_helpers.dashboard_collection_path(coll_2_mgr, locale: 'en')
          expect(coll_2_mgr.member_objects).to match_array [work_1_own, work_2_own, work_5_read]
        end
      end

      context 'and user has no access to a work' do
        it 'adds only members with read access' do
          expect do
            post :update_members, params: { id: coll_2_mgr,
                                            collection: { members: 'add' },
                                            batch_document_ids: [work_3_own.id, work_6_noaccess.id] }
          end.to change { coll_2_mgr.reload.member_objects.size }.by(1)
          expect(response).to redirect_to routes.url_helpers.dashboard_collection_path(coll_2_mgr, locale: 'en')
          expect(coll_2_mgr.member_objects).to match_array [work_1_own, work_2_own, work_3_own]
        end
      end

      context 'and user adds a subcollection' do
        let(:parent_collection) do
          create(:private_collection_lw, id: 'pcol-mgr', title: ['User has manage access to another'], user: other,
                                         with_permission_template: { manage_users: [user] })
        end

        it 'adds collection user created' do
          expect do
            post :update_members, params: { id: parent_collection,
                                            collection: { members: 'add' },
                                            batch_document_ids: [coll_1_own.id] }
          end.to change { parent_collection.reload.member_objects.size }.by(1)
          expect(response).to redirect_to routes.url_helpers.dashboard_collection_path(parent_collection, locale: 'en')
          expect(parent_collection.member_objects).to match_array [coll_1_own]
        end

        it 'adds collection with manage access' do
          expect do
            post :update_members, params: { id: parent_collection,
                                            collection: { members: 'add' },
                                            batch_document_ids: [coll_2_mgr.id] }
          end.to change { parent_collection.reload.member_objects.size }.by(1)
          expect(response).to redirect_to routes.url_helpers.dashboard_collection_path(parent_collection, locale: 'en')
          expect(parent_collection.member_objects).to match_array [coll_2_mgr]
        end

        it 'adds collection with deposit access' do
          expect do
            post :update_members, params: { id: parent_collection,
                                            collection: { members: 'add' },
                                            batch_document_ids: [coll_3_dep.id] }
          end.to change { parent_collection.reload.member_objects.size }.by(1)
          expect(response).to redirect_to routes.url_helpers.dashboard_collection_path(parent_collection, locale: 'en')
          expect(parent_collection.member_objects).to match_array [coll_3_dep]
        end

        it 'adds collection with view access' do
          expect do
            post :update_members, params: { id: parent_collection,
                                            collection: { members: 'add' },
                                            batch_document_ids: [coll_4_view.id] }
          end.to change { parent_collection.reload.member_objects.size }.by(1)
          expect(response).to redirect_to routes.url_helpers.dashboard_collection_path(parent_collection, locale: 'en')
          expect(parent_collection.member_objects).to match_array [coll_4_view]
        end

        it 'displays error message for collection with no access' do
          expect do
            post :update_members, params: { id: parent_collection,
                                            collection: { members: 'add' },
                                            batch_document_ids: [coll_5_noaccess.id] }
          end.to change { parent_collection.reload.member_objects.size }.by(0)
          expect(flash[:alert]).to eq 'You do not have sufficient privileges to any of the selected members'
          expect(response).to redirect_to routes.url_helpers.dashboard_collections_path(locale: 'en')
          expect(parent_collection.member_objects).to match_array []
        end
      end
    end

    context 'when user is depositor of the collection' do
      before do
        sign_in user
        [work_1_own, work_2_own].each do |asset|
          asset.member_of_collections << coll_3_dep
          asset.save!
        end
      end

      context 'and user created the work' do
        it 'adds members to the collection' do
          expect do
            post :update_members, params: { id: coll_3_dep,
                                            collection: { members: 'add' },
                                            batch_document_ids: [work_3_own.id] }
          end.to change { coll_3_dep.reload.member_objects.size }.by(1)
          expect(response).to redirect_to routes.url_helpers.dashboard_collection_path(coll_3_dep, locale: 'en')
          expect(coll_3_dep.member_objects).to match_array [work_1_own, work_2_own, work_3_own]
        end
      end

      context 'and user has edit access to works' do
        it 'adds members to the collection' do
          expect do
            post :update_members, params: { id: coll_3_dep,
                                            collection: { members: 'add' },
                                            batch_document_ids: [work_4_edit.id] }
          end.to change { coll_3_dep.reload.member_objects.size }.by(1)
          expect(response).to redirect_to routes.url_helpers.dashboard_collection_path(coll_3_dep, locale: 'en')
          expect(coll_3_dep.member_objects).to match_array [work_1_own, work_2_own, work_4_edit]
        end
      end

      context 'and user has read access to works' do
        it 'adds members to the collection' do
          expect do
            post :update_members, params: { id: coll_3_dep,
                                            collection: { members: 'add' },
                                            batch_document_ids: [work_5_read.id] }
          end.to change { coll_3_dep.reload.member_objects.size }.by(1)
          expect(response).to redirect_to routes.url_helpers.dashboard_collection_path(coll_3_dep, locale: 'en')
          expect(coll_3_dep.member_objects).to match_array [work_1_own, work_2_own, work_5_read]
        end
      end

      context 'and user has no access to a work' do
        it 'adds only members with read access' do
          expect do
            post :update_members, params: { id: coll_3_dep,
                                            collection: { members: 'add' },
                                            batch_document_ids: [work_3_own.id, work_6_noaccess.id] }
          end.to change { coll_3_dep.reload.member_objects.size }.by(1)
          expect(response).to redirect_to routes.url_helpers.dashboard_collection_path(coll_3_dep, locale: 'en')
          expect(coll_3_dep.member_objects).to match_array [work_1_own, work_2_own, work_3_own]
        end
      end

      context 'and user adds a subcollection' do
        let(:parent_collection) do
          create(:private_collection_lw, id: 'pcol-dep', title: ['User has deposit access to another'], user: other,
                                         with_permission_template: { deposit_users: [user] })
        end

        it 'adds collection user created' do
          expect do
            post :update_members, params: { id: parent_collection,
                                            collection: { members: 'add' },
                                            batch_document_ids: [coll_1_own.id] }
          end.to change { parent_collection.reload.member_objects.size }.by(1)
          expect(response).to redirect_to routes.url_helpers.dashboard_collection_path(parent_collection, locale: 'en')
          expect(parent_collection.member_objects).to match_array [coll_1_own]
        end

        it 'adds collection with manage access' do
          expect do
            post :update_members, params: { id: parent_collection,
                                            collection: { members: 'add' },
                                            batch_document_ids: [coll_2_mgr.id] }
          end.to change { parent_collection.reload.member_objects.size }.by(1)
          expect(response).to redirect_to routes.url_helpers.dashboard_collection_path(parent_collection, locale: 'en')
          expect(parent_collection.member_objects).to match_array [coll_2_mgr]
        end

        it 'adds collection with deposit access' do
          expect do
            post :update_members, params: { id: parent_collection,
                                            collection: { members: 'add' },
                                            batch_document_ids: [coll_3_dep.id] }
          end.to change { parent_collection.reload.member_objects.size }.by(1)
          expect(response).to redirect_to routes.url_helpers.dashboard_collection_path(parent_collection, locale: 'en')
          expect(parent_collection.member_objects).to match_array [coll_3_dep]
        end

        it 'adds collection with view access' do
          expect do
            post :update_members, params: { id: parent_collection,
                                            collection: { members: 'add' },
                                            batch_document_ids: [coll_4_view.id] }
          end.to change { parent_collection.reload.member_objects.size }.by(1)
          expect(response).to redirect_to routes.url_helpers.dashboard_collection_path(parent_collection, locale: 'en')
          expect(parent_collection.member_objects).to match_array [coll_4_view]
        end

        it 'displays error message for collection with no access' do
          expect do
            post :update_members, params: { id: parent_collection,
                                            collection: { members: 'add' },
                                            batch_document_ids: [coll_5_noaccess.id] }
          end.to change { parent_collection.reload.member_objects.size }.by(0)
          expect(flash[:alert]).to eq 'You do not have sufficient privileges to any of the selected members'
          expect(response).to redirect_to routes.url_helpers.dashboard_collections_path(locale: 'en')
          expect(parent_collection.member_objects).to match_array []
        end
      end
    end

    context 'when user is viewer of the collection' do
      before do
        sign_in user
        [work_1_own, work_2_own].each do |asset|
          asset.member_of_collections << coll_4_view
          asset.save!
        end
      end

      context 'and user created the work' do
        it "displays error message if user can't deposit to collection" do
          expect do
            post :update_members, params: { id: coll_4_view,
                                            collection: { members: 'add' },
                                            batch_document_ids: [work_3_own.id] }
          end.to change { coll_4_view.reload.member_objects.size }.by(0)
          expect(flash[:alert]).to eq 'You do not have sufficient privileges to add members to the collection'
          expect(response).to redirect_to routes.url_helpers.dashboard_collections_path(locale: 'en')
          expect(coll_4_view.member_objects).to match_array [work_1_own, work_2_own]
        end
      end
    end

    context 'when members violate the multi-membership checker for single membership collections' do
      let!(:sm_collection_type) { create(:collection_type, title: 'Single Membership', allow_multiple_membership: false) }
      let(:coll_1_sm) { create(:collection_lw, id: 'coll_1_sm', title: ['SM1'], collection_type: sm_collection_type, user: user) }
      let!(:coll_2_sm) { create(:collection_lw, id: 'coll_2_sm', title: ['SM2'], collection_type: sm_collection_type, user: user) }
      let(:base_errmsg) { "Error: You have specified more than one of the same single-membership collection type" }
      let(:regexp) { /#{base_errmsg} \(type: Single Membership, collections: (SM1 and SM2|SM2 and SM1)\)/ }

      before do
        sign_in user
        [work_1_own, work_2_own].each do |asset|
          asset.member_of_collections << coll_1_sm
          asset.save!
          Hyrax.publisher.publish('object.metadata.updated', object: asset.valkyrie_resource, user: user)
        end
        Hyrax.publisher.publish('object.metadata.updated', object: coll_1_sm.valkyrie_resource, user: user)
        Hyrax.publisher.publish('object.metadata.updated', object: coll_2_sm.valkyrie_resource, user: user)
      end

      it "displays error message and deposits works not in violation" do
        expect do
          post :update_members, params: { id: coll_2_sm,
                                          collection: { members: 'add' },
                                          batch_document_ids: [work_1_own.id, work_2_own.id, work_3_own.id] }
        end.to change { coll_2_sm.reload.member_objects.size }.by(1)
        expect(flash[:error]).to match regexp
        expect(response).to redirect_to routes.url_helpers.dashboard_collection_path(coll_2_sm, locale: 'en')
        expect(coll_2_sm.member_objects).to match_array [work_3_own]
      end
    end
  end
end
