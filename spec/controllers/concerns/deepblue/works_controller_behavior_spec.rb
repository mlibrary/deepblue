require 'rails_helper'

class MockDeepblueWorksControllerBehavior < Hyrax::DeepblueController
  include Deepblue::WorksControllerBehavior
  include Deepblue::ZipDownloadControllerBehavior
  include Deepblue::SingleUseLinkControllerBehavior

  attr_accessor :curation_concern, :current_user, :current_ability
end

class Mock2DataSetsController < Hyrax::DataSetsController
end

# This tests the Hyrax::WorksControllerBehavior module
RSpec.describe Hyrax::DataSetsController, :clean_repo do	

  include Devise::Test::ControllerHelpers
  routes { Rails.application.routes }
  let(:main_app) { Rails.application.routes.url_helpers }
  let(:hyrax) { Hyrax::Engine.routes.url_helpers }

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.data_sets_controller_debug_verbose ).to eq( debug_verbose ) }
    it { expect( ::Deepblue::WorksControllerBehavior.deepblue_works_controller_behavior_debug_verbose ).to eq( debug_verbose ) }
    it { expect( ::Hyrax::AnonymousLinkService.anonymous_link_service_debug_verbose ).to eq( debug_verbose ) }
  end

  let(:empty_hash) { {} }

  describe 'all controller tests with debug' do
    RSpec.shared_examples 'shared all controller tests' do |dbg_verbose|
      subject { described_class }
      before do
        described_class.data_sets_controller_debug_verbose = dbg_verbose
        Deepblue::WorksControllerBehavior.deepblue_works_controller_behavior_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose
      end
      after do
        described_class.data_sets_controller_debug_verbose = debug_verbose
        Deepblue::WorksControllerBehavior.deepblue_works_controller_behavior_debug_verbose = debug_verbose
      end
      context 'all' do
        let( :dummy_class )  { MockDeepblueWorksControllerBehavior.new }
        let( :dummy2_class ) { Mock2DataSetsController.new }
        let( :test_object )  { double('test_object') }
        let( :test_object2 ) { double('test_object2') }
        let( :test_user )    { double('test_user') }
        let( :test_actor )   { double('actor') }
        let( :enhanced_env ) { double('enhanced environment') }

        # 'after_create_response'
        # taken care of in spec/controllers/hyrax/data_sets_controller_spec.rb

        # 'after_destroy_response'
        # taken care of in spec/controllers/hyrax/data_sets_controller_spec.rb

        it 'works_render_json_response' do
          allow(dummy_class).to receive(:render).and_return "done"
          allow(Hyrax::API).to receive(:generate_response_body).and_return "abc"

          dc = dummy_class.works_render_json_response
          expect(dc).to eq("done")
        end

        # 'after_update_response'
        # taken care of in spec/controllers/hyrax/data_sets_controller_spec.rb

        # 'build_form'
        # taken care of in spec/controllers/hyrax/data_sets_controller_spec.rb

        # 'create'
        # taken care of in spec/controllers/hyrax/data_sets_controller_spec.rb

        it 'create_anonymous_link' do
          allow(dummy_class).to receive(:params).and_return({:commit => "Create Download Anonymous Link"})
          allow(dummy_class).to receive(:current_show_path).and_return "/data"
          allow(dummy_class).to receive(:current_ability).and_return test_object
          allow(test_object).to receive(:current_user).and_return test_object2
          allow(test_object2).to receive(:id).and_return "abc"

          expect(::AnonymousLink).to receive(:create).with( any_args )
          allow(dummy_class).to receive(:curation_concern).and_return test_object
          allow(test_object).to receive(:id).and_return "abc"
          allow(dummy_class).to receive(:redirect_to).and_return "here"

          dc = dummy_class.create_anonymous_link
          expect(dc).to eq("here")
        end

        it 'create_single_use_link' do
          allow(dummy_class).to receive(:params).and_return({:commit => "Create Download Single-Use Link"})
          allow(dummy_class).to receive(:current_show_path).and_return "/data"
          allow(dummy_class).to receive(:current_ability).and_return test_object
          allow(test_object).to receive(:current_user).and_return test_object2
          allow(test_object2).to receive(:id).and_return "abc"

          expect(::SingleUseLink).to receive(:create).with( any_args )
          allow(dummy_class).to receive(:curation_concern).and_return test_object
          allow(test_object).to receive(:id).and_return "abc"
          allow(dummy_class).to receive(:redirect_to).and_return "here"

          dc = dummy_class.create_single_use_link
          expect(dc).to eq("here")
        end

        it 'can_delete_work?' do
          allow(dummy_class).to receive(:anonymous_link?).and_return true
          allow(dummy_class).to receive(:doi?).and_return false
          allow(dummy_class).to receive(:tombstoned?).and_return false

          allow(dummy_class).to receive(:current_ability).and_return test_object
          allow(test_object).to receive(:admin?).and_return false

          dc = dummy_class.can_delete_work?
          expect(dc).to eq(false)
        end

        it 'can_delete_work?' do
          allow(dummy_class).to receive(:anonymous_link?).and_return false
          allow(dummy_class).to receive(:doi?).and_return true
          allow(dummy_class).to receive(:tombstoned?).and_return false

          allow(dummy_class).to receive(:current_ability).and_return test_object
          allow(test_object).to receive(:admin?).and_return false

          dc = dummy_class.can_delete_work?
          expect(dc).to eq(false)
        end

        it 'can_delete_work?' do
          allow(dummy_class).to receive(:anonymous_link?).and_return false
          allow(dummy_class).to receive(:doi?).and_return false
          allow(dummy_class).to receive(:tombstoned?).and_return false

          allow(dummy_class).to receive(:current_ability).and_return test_object
          allow(test_object).to receive(:admin?).and_return true

          dc = dummy_class.can_delete_work?
          expect(dc).to eq(true)
        end

        it 'can_subscribe_to_analytics_reports? (1)' do
          allow(AnalyticsHelper).to receive(:enable_local_analytics_ui?).and_return false
          allow(dummy_class).to receive(:anonymous_link?).and_return false
          allow(dummy_class).to receive(:current_ability).and_return test_object
          allow(test_object).to receive(:admin?).and_return false

          allow(dummy_class).to receive(:curation_concern).and_return test_object
          allow(test_object).to receive(:depositor).and_return "test@umich.edu"
          allow(dummy_class).to receive(:editor?).and_return true
          allow(test_object).to receive(:current_user).and_return test_object2
          allow(test_object2).to receive(:email).and_return "test@umich.edu"

          dc = dummy_class.can_subscribe_to_analytics_reports?
          expect(dc).to eq(false)
        end

        it 'can_subscribe_to_analytics_reports? (2)' do
          allow(AnalyticsHelper).to receive(:enable_local_analytics_ui?).and_return true
          allow(dummy_class).to receive(:anonymous_link?).and_return true
          allow(dummy_class).to receive(:current_ability).and_return test_object
          allow(test_object).to receive(:admin?).and_return false

          allow(dummy_class).to receive(:curation_concern).and_return test_object
          allow(test_object).to receive(:depositor).and_return "test@umich.edu"
          allow(test_object).to receive(:current_user).and_return test_object2
          allow(test_object2).to receive(:email).and_return "test@umich.edu"

          dc = dummy_class.can_subscribe_to_analytics_reports?
          expect(dc).to eq(false)
        end

        it 'can_subscribe_to_analytics_reports? (3)' do
          allow(AnalyticsHelper).to receive(:enable_local_analytics_ui?).and_return true
          allow(AnalyticsHelper).to receive(:analytics_reports_admins_can_subscribe?).and_return true
          allow(dummy_class).to receive(:anonymous_link?).and_return false
          allow(dummy_class).to receive(:can_edit_work?).and_return true
          allow(dummy_class).to receive(:current_ability).and_return test_object
          allow(test_object).to receive(:admin?).and_return true

          allow(dummy_class).to receive(:curation_concern).and_return test_object
          allow(test_object).to receive(:depositor).and_return "test@umich.edu"
          allow(test_object).to receive(:current_user).and_return test_object2
          allow(test_object2).to receive(:email).and_return "test@umich.edu"

          dc = dummy_class.can_subscribe_to_analytics_reports?
          expect(dc).to eq(true)
        end

        it 'can_subscribe_to_analytics_reports? (4)' do
          allow(AnalyticsHelper).to receive(:enable_local_analytics_ui?).and_return true
          allow(AnalyticsHelper).to receive(:analytics_reports_admins_can_subscribe?).and_return true
          allow(AnalyticsHelper).to receive(:open_analytics_report_subscriptions?).and_return true
          allow(dummy_class).to receive(:anonymous_link?).and_return false
          allow(dummy_class).to receive(:can_edit_work?).and_return true
          allow(dummy_class).to receive(:current_ability).and_return test_object
          allow(test_object).to receive(:admin?).and_return false

          allow(dummy_class).to receive(:curation_concern).and_return test_object
          allow(test_object).to receive(:depositor).and_return "test@umich.edu"
          allow(test_object).to receive(:current_user).and_return test_object2
          allow(test_object2).to receive(:email).and_return "test@umich.edu"

          dc = dummy_class.can_subscribe_to_analytics_reports?
          expect(dc).to eq(true)
        end

        it 'can_subscribe_to_analytics_reports? (5)' do
          allow(AnalyticsHelper).to receive(:enable_local_analytics_ui?).and_return true
          allow(AnalyticsHelper).to receive(:analytics_reports_admins_can_subscribe?).and_return true
          allow(AnalyticsHelper).to receive(:open_analytics_report_subscriptions?).and_return true
          allow(dummy_class).to receive(:anonymous_link?).and_return false
          allow(dummy_class).to receive(:can_edit_work?).and_return false
          allow(dummy_class).to receive(:current_ability).and_return test_object

          allow(test_object).to receive(:admin?).and_return false
          allow(test_object).to receive(:current_user).and_return test_user
          allow(test_user).to receive(:email).and_return "test@umich.edu"

          allow(dummy_class).to receive(:curation_concern).and_return test_object
          allow(test_object).to receive(:depositor).and_return "test@umich.edu"

          dc = dummy_class.can_subscribe_to_analytics_reports?
          expect(dc).to eq(true)
        end

        it 'can_edit_work?' do
          allow(dummy_class).to receive(:anonymous_link?).and_return false
          allow(dummy_class).to receive(:current_ability).and_return test_object
          allow(test_object).to receive(:admin?).and_return false
          allow(dummy_class).to receive(:editor?).and_return true
          allow(dummy_class).to receive(:workflow_state).and_return "active"

          dc = dummy_class.can_edit_work?
          expect(dc).to eq(true)
        end

        # 'destroy'
        # taken care of in spec/controllers/hyrax/data_sets_controller_spec.rb

        it 'destroy_rest' do
          allow(dummy_class).to receive(:curation_concern).and_return test_object
          allow(test_object).to receive(:workflow_state).and_return true
          allow(test_object).to receive(:id).and_return "abc"
          expect(Hyrax.config.callback).to receive(:run).with( any_args )
          allow(dummy_class).to receive(:actor).and_return(test_actor)
          allow(test_actor).to receive(:destroy).and_return true
          allow(dummy_class).to receive(:actor_environment).and_return true
          allow(dummy_class).to receive(:after_destroy_response).and_return true

          dc = dummy_class.destroy_rest
          expect(dc).to eq(true)
        end

        # 'new'
        # taken care of in spec/controllers/hyrax/data_sets_controller_spec.rb

        it 'new_rest' do
          allow(dummy_class).to receive(:curation_concern).and_return test_object
          allow(test_object).to receive(:depositor=)
          allow(test_object).to receive(:admin_set_id=)
          allow(dummy_class).to receive(:current_user).and_return test_object
          allow(test_object).to receive(:user_key).and_return "abc"
          allow(dummy_class).to receive(:admin_set_id_for_new).and_return "abc"
          allow(dummy_class).to receive(:build_form).and_return true

          dc = dummy_class.new_rest
          expect(dc).to eq(true)
        end

        it 'anonymous_link' do
          allow(dummy_class).to receive(:params).and_return({:id => "anID", :anon_link_id => "abc"})
          allow(test_object).to receive(:id).and_return "anID"
          allow(::Deepblue::WorkViewContentService).to receive(:content_find_by_id).and_return test_object
          allow(test_object).to receive(:tombstone).and_return true
          allow(dummy_class).to receive(:redirect_to).and_return "here"
          allow(dummy_class).to receive(:main_app).and_return test_object
          allow(test_object).to receive(:root_path).and_return "/data"
          allow(dummy_class).to receive(:polymorphic_path).and_return "polymorphic_path"

          dc = dummy_class.anonymous_link
          expect(dc).to eq("here")
        end

        it 'single_use_link' do
          allow(dummy_class).to receive(:params).and_return({:link_id => "abc"})
          allow(::Deepblue::WorkViewContentService).to receive(:content_find_by_id).and_return test_object
          allow(test_object).to receive(:tombstone).and_return true
          allow(dummy_class).to receive(:redirect_to).and_return "here"
          allow(dummy_class).to receive(:main_app).and_return test_object
          allow(test_object).to receive(:root_path).and_return "/data"
          allow(test_object).to receive(:id).and_return "id"

          dc = dummy_class.single_use_link
          expect(dc).to eq("here")
        end

        it 'presenter_init and return the presenter' do
          allow(dummy_class).to receive(:presenter).and_return true
          allow(dummy2_class).to receive(:read_me_file_set).and_return true
          allow(dummy_class).to receive(:_curation_concern_type).and_return test_object
          allow(test_object).to receive(:find_with_rescue).and_return test_object

          dc = dummy_class.presenter_init
          expect(dc).to eq(true)
        end

        it 'search_result_document' do
          allow(dummy_class).to receive(:anonymous_link?).and_return true
          allow(dummy_class).to receive(:params).and_return({:link_id => "abc"})
          expect(::SolrDocument).to receive(:find).with( any_args )


          dc = dummy_class.search_result_document("abc")
          expect(dc).to eq(nil)
        end

        it 'single_use_link_zip_download' do
          allow(dummy_class).to receive(:params).and_return({:id => "abc"})
          allow(::Deepblue::WorkViewContentService).to receive(:content_find_by_id).with( any_args ).and_return test_object
          allow(dummy_class).to receive(:single_use_link_obj).and_return "test"
          allow(dummy_class).to receive(:main_app).and_return test_object
          allow(dummy_class).to receive(:redirect_to).and_return "here"
          allow(test_object).to receive(:root_path).and_return "path"
          allow(test_object).to receive(:tombstone).and_return "test"
          allow(test_object).to receive(:id).and_return "id"
          allow(dummy_class).to receive(:single_use_link_destroy!).and_return true

          dc = dummy_class.single_use_link_zip_download
          expect(dc).to eq("here")
        end

        it 'single_use_link_zip_download without tombstone' do
          allow(dummy_class).to receive(:params).and_return({:id => "abc"})
          allow(::Deepblue::WorkViewContentService).to receive(:content_find_by_id).with( any_args ).and_return test_object

          allow(dummy_class).to receive(:single_use_link_obj).and_return "test"
          allow(dummy_class).to receive(:main_app).and_return test_object
          allow(dummy_class).to receive(:redirect_to).and_return "here"
          allow(dummy_class).to receive(:polymorphic_path).and_return "poly"
          allow(dummy_class).to receive(:single_use_link_valid?).and_return true

          allow(test_object).to receive(:root_path).and_return "path"
          allow(test_object).to receive(:id).and_return "abc"
          allow(test_object).to receive(:single_use_link_destroy!).and_return nil
          allow(test_object).to receive(:tombstone).and_return nil
          allow(dummy_class).to receive(:single_use_link_destroy!).and_return true
          allow(dummy_class).to receive(:zip_download).and_return "done"

          dc = dummy_class.single_use_link_zip_download
          expect(dc).to eq("done")
        end

        it 'single_use_link_request?' do
          allow(dummy_class).to receive(:params).and_return({:link_id => "abc", :action => "single_use_link"})

          dc = dummy_class.single_use_link_request?
          expect(dc).to eq(true)
        end

        # 'show'
        # taken care of in spec/controllers/hyrax/data_sets_controller_spec.rb

        # 'update'
        # tested in spec/controllers/hyrax/data_sets_controller_spec.rb

        it 'update_rest' do
          allow(dummy_class).to receive(:curation_concern).and_return test_object
          # allow(dummy_class).to receive(:actor_environment).and_return true
          allow(dummy_class).to receive(:actor).and_return test_object
          allow(test_object).to receive(:update).and_return true
          allow(test_object).to receive(:id).and_return 'id'
          allow(test_object).to receive(:errors).and_return []
          allow(dummy_class).to receive(:after_update_response).and_return true
          allow(dummy_class).to receive(:data_set_version?).and_return true
          allow(dummy_class).to receive(:attributes_for_actor).and_return empty_hash
          allow(dummy_class).to receive(:params).and_return empty_hash

          dc = dummy_class.update_rest "no_id"
          expect(dc).to eq(nil)
        end

        it 'attributes_for_actor_json' do
          allow(dummy_class).to receive(:curation_concern).and_return test_object
          allow(dummy_class).to receive(:params).and_return({:id => "abc"})
          allow(dummy_class).to receive(:hash_key_for_curation_concern).and_return :id
          allow(dummy_class).to receive(:actor).and_return test_object
          allow(::ActionController::ParametersTrackErrors).to receive(:new).and_return "abc"
          allow(dummy_class).to receive(:work_form_service).and_return test_object
          allow(test_object).to receive(:form_class).and_return test_object
          allow(test_object).to receive(:name).and_return "FormClassName"
          allow(test_object).to receive(:model_attributes_json).and_return "test"
          allow(test_object).to receive(:to_h).and_return empty_hash
          allow(dummy_class).to receive(:data_set_version?).and_return true

          dc = dummy_class.attributes_for_actor_json
          expect(dc).to eq("test")
        end

        it 'actor_environment' do
          allow(dummy_class).to receive(:params).and_return({:data_set => {:id => "123"}})
          allow(dummy_class).to receive(:data_set_version?).and_return true
          allow(dummy_class).to receive(:attributes_for_actor).and_return test_object
          allow(test_object).to receive(:errors).and_return ["there is an error"]
          allow(test_object).to receive(:size).and_return 1
          allow(dummy_class).to receive(:curation_concern).and_return test_object2
          allow(test_object2).to receive(:errors).and_return test_object
          allow(test_object2).to receive(:id).and_return 'id'
          allow(test_object).to receive(:add).and_return "done"
          # allow(::Hyrax::Actors::EnvironmentEnhanced).to receive(:new).with(:any_args).and_return enhanced_env
          # allow(enhanced_env).to receive(:attributes).and_return empty_hash
          allow(test_object).to receive(:to_h).and_return empty_hash

          dc = dummy_class.actor_environment
          expect(dc.class.name).to eq("Hyrax::Actors::EnvironmentEnhanced")
          expect(dc.action).to eq(nil)
          expect(dc.wants_format).to eq(nil)
        end

        it 'save_permissions' do
          allow(dummy_class).to receive(:curation_concern).and_return test_object
          allow(test_object).to receive(:permissions).and_return test_object2
          allow(test_object2).to receive(:to_hash).and_return "abc"
          allow(test_object2).to receive(:map).and_return "done"

          dc = dummy_class.save_permissions
          expect(dc).to eq("done")
        end

        it 'permissions_changed?' do
          allow(dummy_class).to receive(:curation_concern).and_return test_object
          allow(test_object).to receive(:permissions).and_return test_object2
          allow(test_object2).to receive(:to_hash).and_return "abc"
          allow(test_object2).to receive(:map).and_return "done"

          dc = dummy_class.permissions_changed?
          expect(dc).to eq(true)
        end
      end
    end
    it_behaves_like 'shared all controller tests', false
    it_behaves_like 'shared all controller tests', true
  end

  describe 'all controller tests with no debug statements' do
    RSpec.shared_examples 'shared all controller tests with no debug statements' do |dbg_verbose|
      subject { described_class }
      before do
        described_class.data_sets_controller_debug_verbose = dbg_verbose
        Deepblue::WorksControllerBehavior.deepblue_works_controller_behavior_debug_verbose = dbg_verbose

        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug)
      end
      after do
        described_class.data_sets_controller_debug_verbose = debug_verbose
        Deepblue::WorksControllerBehavior.deepblue_works_controller_behavior_debug_verbose = debug_verbose
      end
      context 'all' do
        let( :dummy_class )  { MockDeepblueWorksControllerBehavior.new }
        let( :dummy2_class ) { Mock2DataSetsController.new }
        let( :test_object )  { double('test_object') }
        let( :test_object2 ) { double('test_object2') }
        let( :test_user )    { double('test_user') }
        let( :test_actor )   { double('actor') }
        let( :enhanced_env ) { double('enhanced environment') }

        context '' do

          it 'anonymous_link?' do
            allow(dummy_class).to receive(:params).and_return({:anon_link_id => "abc"})

            dc = dummy_class.anonymous_link?
            expect(dc).to eq(true)
          end

          it 'attributes_for_actor' do
            dc = dummy_class.attributes_for_actor
            expect(dc).to eq({})
          end

          it 'current_show_path' do
            allow(dummy_class).to receive(:polymorphic_path).and_return "abc"

            dc = dummy_class.current_show_path
            expect(dc).to eq("abc")
          end

          it 'data_set_version?' do
            allow(dummy_class).to receive(:params).and_return({:data_set => {:id => "123"}})

            dc = dummy_class.data_set_version?
            expect(dc).to eq(false)
          end

          it 'doi?' do
            allow(dummy_class).to receive(:curation_concern).and_return test_object
            allow(test_object).to receive(:doi).and_return true

            dc = dummy_class.doi?
            expect(dc).to eq(true)
          end

          it 'editor?' do
            allow(dummy_class).to receive(:anonymous_link?).and_return false
            allow(dummy_class).to receive(:current_ability).and_return test_object
            allow(test_object).to receive(:can?).and_return true

            allow(dummy_class).to receive(:curation_concern).and_return test_object
            allow(test_object).to receive(:id).and_return "abc"

            dc = dummy_class.editor?
            expect(dc).to eq(true)
          end

          it 'tombstoned?' do
            allow(dummy_class).to receive(:curation_concern).and_return test_object
            allow(test_object).to receive(:tombstone).and_return true

            dc = dummy_class.tombstoned?
            expect(dc).to eq(true)
          end

          it 'update_allow_json?' do
            allow(dummy_class).to receive(:data_set_version?).and_return false
            allow(::DeepBlueDocs::Application).to receive(:config).and_return test_object
            allow(test_object).to receive(:rest_api_allow_mutate).and_return "done"

            dc = dummy_class.update_allow_json?
            expect(dc).to eq(true)
            #expect(dc).to eq("done")
          end

          it 'workflow_state' do
            allow(dummy_class).to receive(:curation_concern).and_return test_object
            allow(test_object).to receive(:workflow_state).and_return true

            dc = dummy_class.workflow_state
            expect(dc).to eq(true)
          end

        end
      end
    end
    it_behaves_like 'shared all controller tests with no debug statements', false
    it_behaves_like 'shared all controller tests with no debug statements', true
  end

end
