# frozen_string_literal: true

# keywords: example send

require 'rails_helper'

require_relative "../../../app/services/deepblue/new_content_service2"

# Use this mock to create instances that are not fully instantiated in order
# to test methods that are independent of the state of the object.
# And to get access to protected and private methods without using "send".
class MockNewContentService2 < ::Deepblue::NewContentService2

  def initialize_with_msg( options:,
                           path_to_yaml_file:,
                           cfg_hash:,
                           base_path:,
                           mode: nil,
                           ingester: nil,
                           use_rails_logger: false,
                           user_create: DEFAULT_USER_CREATE,
                           msg: "NEW CONTENT SERVICE AT YOUR ... SERVICE",
                           **config )

    # ignore for testing purposes
  end

  def update_cc_attribute( curation_concern:, attribute:, value: )
    super( curation_concern: curation_concern, attribute: attribute, value: value )
  end

  def update_cc_edit_users( curation_concern:, edit_users: )
    super( curation_concern: curation_concern, edit_users: edit_users )
  end

  def update_cc_read_users( curation_concern:, read_users: )
    super( curation_concern: curation_concern, read_users: read_users )
  end

  def update_visibility( curation_concern:, visibility: )
    super( curation_concern: curation_concern, visibility: visibility )
  end

  def valid_restricted_vocab( value, var:, vocab:, error_class: RestrictedVocabularyError )
    super( value, var: var, vocab: vocab, error_class: error_class )
  end

  def visibility_curation_concern( vis )
    super( vis )
  end

end

RSpec.describe ::Deepblue::NewContentService2, skip: false do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.new_content_service_debug_verbose ).to eq debug_verbose }
  end

  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:base_path) { "./fixtures" }
  let(:path_to_yaml_file) { "./fixtures/test_populate.yml" }

  describe 'constants' do
    it "resolves them" do
      expect( described_class.new_content_service_debug_verbose ).to eq debug_verbose
      expect( described_class::DEFAULT_DATA_SET_ADMIN_SET_NAME ).to eq Rails.configuration.data_set_admin_set_title
      expect( described_class::DEFAULT_DIFF_ATTRS_SKIP ).to eq [ :creator_ordered,
                                                                 :creator_orcid_ordered,
                                                                 :curation_notes_admin_ordered,
                                                                 :curation_notes_user_ordered,
                                                                 :date_created, :date_modified,
                                                                 :description_ordered,
                                                                 :keyword_ordered, :language_ordered,
                                                                 :methodology_ordered,
                                                                 :referenced_by_ordered, :title_ordered,
                                                                 :visibility ]
      expect( described_class::DEFAULT_DIFF_ATTRS_SKIP_IF_BLANK ).to eq [ :creator_ordered,
                                                                          :creator_orcid_ordered,
                                                                          :curation_notes_admin,
                                                                          :curation_notes_admin_ordered,
                                                                          :curation_notes_user,
                                                                          :curation_notes_user_ordered,
                                                                          :checksum_algorithm, :checksum_value,
                                                                          :date_published,
                                                                          :description_ordered,
                                                                          :doi,
                                                                          :fundedby_other,
                                                                          :keyword_ordered, :language_ordered,
                                                                          :methodology_ordered,
                                                                          :prior_identifier,
                                                                          :referenced_by_ordered, :title_ordered ]
      expect( described_class::DEFAULT_DIFF_USER_ATTRS_SKIP ).to eq [ :created_at,
                                       :current_sign_in_at, :current_sign_in_ip,
                                       :email, :encrypted_password,
                                       :id,
                                       :updated_at ]
      expect( described_class::DEFAULT_DIFF_COLLECTIONS_RECURSE ).to eq false
      expect( described_class::DEFAULT_EMAIL_AFTER ).to eq false
      expect( described_class::DEFAULT_EMAIL_AFTER_ADD_LOG_MSGS ).to eq true
      expect( described_class::DEFAULT_EMAIL_BEFORE ).to eq false
      expect( described_class::DEFAULT_EMAIL_EACH ).to eq false
      expect( described_class::DEFAULT_EMAIL_DEPOSITOR ).to eq false
      expect( described_class::DEFAULT_EMAIL_INGESTER ).to eq false
      expect( described_class::DEFAULT_EMAIL_OWNER ).to eq false
      expect( described_class::DEFAULT_EMAIL_REST ).to eq false
      expect( described_class::DEFAULT_EMAIL_TEST_MODE ).to eq false
      expect( described_class::DEFAULT_SKIP_ADDING_PRIOR_IDENTIFIER ).to eq true
      expect( described_class::DEFAULT_UPDATE_ADD_FILES ).to eq true
      expect( described_class::DEFAULT_UPDATE_ATTRS_SKIP ).to eq [ :creator_ordered,
                                                                   :creator_orcid_ordered,
                                                                   :curation_notes_admin_ordered,
                                                                   :curation_notes_user_ordered,
                                                                   :date_created, :date_modified, :date_uploaded,
                                                                   :edit_users,
                                                                   :read_users,
                                                                   :keyword_ordered, :language_ordered,
                                                                   :original_name,
                                                                   :referenced_by_ordered, :title_ordered,
                                                                   :visibility ]
      expect( described_class::DEFAULT_UPDATE_ATTRS_SKIP_IF_BLANK ).to eq [ :creator_ordered,
                                                                            :creator_orcid_ordered,
                                                                            :curation_notes_admin,
                                                                            :curation_notes_admin_ordered,
                                                                            :curation_notes_user,
                                                                            :curation_notes_user_ordered,
                                                                            :checksum_algorithm, :checksum_value,
                                                                            :description_ordered, :doi,
                                                                            :fundedby_other, :keyword_ordered,
                                                                            :language_ordered,
                                                                            :methodology_ordered,
                                                                            :prior_identifier,
                                                                            :referenced_by_ordered, :title_ordered ]
      expect( described_class::DEFAULT_UPDATE_COLLECTIONS_RECURSE ).to eq false
      expect( described_class::DEFAULT_UPDATE_DELETE_FILES ).to eq true
      expect( described_class::DEFAULT_UPDATE_USER_ATTRS_SKIP ).to eq [ :created_at,
                                         :current_sign_in_at, :current_sign_in_ip,
                                         :email, :encrypted_password,
                                         :id,
                                         :updated_at ]
      expect( described_class::DEFAULT_USER_CREATE ).to eq true
      expect( described_class::DEFAULT_VERBOSE ).to eq true
      expect( described_class::DIFF_DATES ).to eq false
      expect( ::Deepblue::DoiMintingService::DOI_MINT_NOW ).to eq 'mint_now'
      expect( described_class::MODE_APPEND ).to eq 'append'
      expect( described_class::MODE_BUILD ).to eq 'build'
      expect( described_class::MODE_DIFF ).to eq 'diff'
      expect( described_class::MODE_MIGRATE ).to eq 'migrate'
      expect( described_class::MODE_UPDATE ).to eq 'update'
      expect( described_class::DEFAULT_UPDATE_BUILD_MODE ).to eq described_class::MODE_MIGRATE
      expect( described_class::SOURCE_DBDv1 ).to eq 'DBDv1' # rubocop:disable Style/ConstantName
      expect( described_class::SOURCE_DBDv2 ).to eq 'DBDv2' # rubocop:disable Style/ConstantName
      expect( described_class::STOP_NEW_CONTENT_SERVICE_FILE_NAME ).to eq 'stop_umrdr_new_content'

    end
  end

  describe "script independent methods" do
    let(:attr)     { :curation_notes_admin }
    let(:attr_old) { [] }
    let(:attr_new) { ['New admin curation note.'] }
    let(:user_list_1) { [user.email] }
    let(:user_list_2) { [user2.email] }
    let(:visibility_old) { 'restricted' }
    let(:visibility_new) { 'open' }
    let(:combined_user_list) { user_list_1 + user_list_2 }
    let(:new_content_service) { MockNewContentService2.new( path_to_yaml_file: path_to_yaml_file,
                                                           cfg_hash: {},
                                                           base_path: base_path,
                                                           options: {} ) }

    # before do
    #   expect( new_content_service ).to receive(:initialize_with_msg).with( options: {},
    #                                                                         path_to_yaml_file: path_to_yaml_file,
    #                                                                         cfg_hash: {},
    #                                                                         base_path: base_path )
    # end

    describe ".state_curation_concern" do
      let(:error_msg) {"Illegal value 'not_valid_state' state, must be one of [\"active\", \"deleted\", \"inactive\", \"unknown\"]" }

      it "says 'active' is valid" do
        expect(new_content_service.send( :state_curation_concern, 'active' )).to eq 'active'
      end

      it "says 'deleted' is valid" do
        expect(new_content_service.send( :state_curation_concern, 'deleted' )).to eq 'deleted'
      end

      it "says 'inactive' is valid" do
        expect(new_content_service.send( :state_curation_concern, 'inactive' )).to eq 'inactive'
      end

      it "throws error for 'not_valid_state'" do
        expect { new_content_service.send( :state_curation_concern,
                                         'not_valid_state' ) }.to raise_error(::Deepblue::NewContentService2::StateError,
                                                                             error_msg)
      end

    end

    describe ".state_from_hash" do
      let(:active_state) { 'active' }
      let(:inactive_state) { 'inactive' }
      let(:hash_with_state) { { state: inactive_state } }
      let(:hash_without_state) { {} }

      it 'returns state from hash' do
        expect(new_content_service.send( :state_from_hash, hash: hash_with_state ) ).to eq inactive_state
      end

      it 'returns active state when hash does not have state' do
        expect(new_content_service.send( :state_from_hash, hash: hash_without_state ) ).to eq active_state
      end

    end

    describe ".update_cc_attributes" do

      context "collection" do
        let(:curation_concern) { build(:collection, user: user) }
        before do
          expect(curation_concern[attr]).to eq attr_old
        end
        it "updates a collection attribute" do
          new_content_service.update_cc_attribute( curation_concern: curation_concern,
                                                   attribute: attr,
                                                   value: attr_new )
          expect(curation_concern[attr]).to eq attr_new
        end
      end

      context "data set" do
        let(:curation_concern) { build(:data_set, user: user) }
        before do
          expect(curation_concern[attr]).to eq attr_old
        end
        it "updates a data_set attribute" do
          new_content_service.update_cc_attribute( curation_concern: curation_concern,
                                                   attribute: attr,
                                                   value: attr_new )
          expect(curation_concern[attr]).to eq attr_new
        end
      end

      context "file set" do
        let(:curation_concern) { build(:file_set, user: user) }
        before do
          expect(curation_concern[attr]).to eq attr_old
        end
        it "updates a file_set attribute" do
          new_content_service.update_cc_attribute( curation_concern: curation_concern,
                                                   attribute: attr,
                                                   value: attr_new )
          expect(curation_concern[attr]).to eq attr_new
        end
      end

    end

    describe ".update_cc_edit_users" do

      context "collection" do
        let(:curation_concern) { build(:collection, user: user) }
        before do
          expect(curation_concern.edit_users).to eq user_list_1
        end
        it "updates a collection edit users" do
          new_content_service.update_cc_edit_users( curation_concern: curation_concern, edit_users: user_list_1 )
          expect( curation_concern.edit_users ).to eq user_list_1
          new_content_service.update_cc_edit_users( curation_concern: curation_concern, edit_users: user_list_2 )
          expect( curation_concern.edit_users ).to eq combined_user_list
        end
      end

      context "data set" do
        let(:curation_concern) { build(:data_set, user: user) }
        before do
          expect(curation_concern.edit_users).to eq user_list_1
        end
        it "updates a data_set edit users" do
          new_content_service.send( :update_cc_edit_users, curation_concern: curation_concern, edit_users: user_list_1 )
          expect( curation_concern.edit_users ).to eq user_list_1
          new_content_service.send( :update_cc_edit_users, curation_concern: curation_concern, edit_users: user_list_2 )
          expect( curation_concern.edit_users ).to eq combined_user_list
        end
      end

      context "file set" do
        let(:curation_concern) { build(:file_set, user: user) }
        before do
          expect(curation_concern.edit_users).to eq user_list_1
        end
        it "updates a file_set edit users" do
          new_content_service.send( :update_cc_edit_users, curation_concern: curation_concern, edit_users: user_list_1 )
          expect( curation_concern.edit_users ).to eq user_list_1
          new_content_service.send( :update_cc_edit_users, curation_concern: curation_concern, edit_users: user_list_2 )
          expect( curation_concern.edit_users ).to eq combined_user_list
        end
      end

    end

    describe ".update_cc_read_users" do

      context "collection" do
        let(:curation_concern) { build(:collection, user: user) }
        before do
          expect(curation_concern.read_users).to eq []
        end
        it "updates a collection edit users" do
          new_content_service.update_cc_read_users( curation_concern: curation_concern, read_users: user_list_1 )
          expect( curation_concern.read_users ).to eq user_list_1
          new_content_service.update_cc_read_users( curation_concern: curation_concern, read_users: user_list_2 )
          expect( curation_concern.read_users ).to eq combined_user_list
        end
      end

      context "data set" do
        let(:curation_concern) { build(:data_set, user: user) }
        before do
          expect(curation_concern.read_users).to eq []
        end
        it "updates a data_set read users" do
          new_content_service.update_cc_read_users( curation_concern: curation_concern, read_users: user_list_1 )
          expect( curation_concern.read_users ).to eq user_list_1
          new_content_service.update_cc_read_users( curation_concern: curation_concern, read_users: user_list_2 )
          expect( curation_concern.read_users ).to eq combined_user_list
        end
      end

      context "file set" do
        let(:curation_concern) { build(:file_set, user: user) }
        before do
          expect(curation_concern.read_users).to eq []
        end
        it "updates a file_set edit users" do
          new_content_service.send( :update_cc_read_users, curation_concern: curation_concern, read_users: user_list_1 )
          expect( curation_concern.read_users ).to eq user_list_1
          new_content_service.send( :update_cc_read_users, curation_concern: curation_concern, read_users: user_list_2 )
          expect( curation_concern.read_users ).to eq combined_user_list
        end
      end

    end

    describe ".update_visibility" do

      # TODO add tests for assigning same visibility, and attempting to assign illegal visibility value

      context "collection" do
        let(:curation_concern) { build(:collection, user: user) }
        before do
          expect(curation_concern.visibility).to eq 'open'
        end
        it "updates a collection attribute" do
          new_content_service.update_visibility( curation_concern: curation_concern, visibility: 'restricted' )
          expect(curation_concern.visibility).to eq 'restricted'
        end
      end

      context "data set" do
        let(:curation_concern) { build(:data_set, user: user) }
        before do
          expect(curation_concern.visibility).to eq visibility_old
        end
        it "updates a data_set attribute" do
          new_content_service.update_visibility( curation_concern: curation_concern, visibility: visibility_new )
          expect(curation_concern.visibility).to eq visibility_new
        end
      end

      context "file set" do
        let(:curation_concern) { build(:file_set, user: user) }
        before do
          expect(curation_concern.visibility).to eq visibility_old
        end
        it "updates a file_set attribute" do
          new_content_service.update_visibility( curation_concern: curation_concern, visibility: visibility_new )
          expect(curation_concern.visibility).to eq visibility_new
        end
      end

    end


      describe ".valid_restricted_vocab" do
        let(:value_included) { 'included value' }
        let(:value_not_included) { 'missing value' }
        let(:var) { 'the_var' }
        let(:vocab) { [ 'value1', value_included, 'value2' ] }
        let(:error_msg) {"Illegal value 'missing value' the_var, must be one of [\"value1\", \"included value\", \"value2\"]" }

        it 'works for value included in vocab' do
          expect(new_content_service.send( :valid_restricted_vocab, value_included, var: var, vocab: vocab ) ).to eq value_included
        end

        it 'throws error when value not included in vocab' do
          expect { new_content_service.send( :valid_restricted_vocab,
                                             value_not_included,
                                             var: var,
                                             vocab: vocab ) }.to raise_error(::Deepblue::NewContentService2::RestrictedVocabularyError,
                                                                             error_msg)
        end

      end

    end

end
