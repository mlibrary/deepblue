require 'rails_helper'

RSpec.describe Hyrax::DataSetsController, :clean_repo do

  include Devise::Test::ControllerHelpers
  routes { Rails.application.routes }
  let(:main_app) { Rails.application.routes.url_helpers }
  let(:hyrax) { Hyrax::Engine.routes.url_helpers }

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.data_sets_controller_debug_verbose ).to eq debug_verbose }
  end

  let(:user)       { create(:user) }
  let(:user_other) { create(:user) }
  let(:admin)      { create(:admin) }

  before do
    sign_in user
    # TODO: This is a big hammer, fix the references of these more appropriately
    # The problem when these aren't defined, is (I suspect) that the TicketHelper code is attempting to find
    # and load the DataSet using PersistHelper.find
    allow(::Deepblue::TicketHelper).to receive(:new_ticket)
    allow(::Deepblue::TicketHelper).to receive(:new_ticket_if_necessary)
    allow(Flipflop).to receive(:enabled?).with(:hyrax_orcid).and_return(true)
    allow(Flipflop).to receive(:hyrax_orcid?).and_return true
  end

  describe 'dbg_verbose true or false', skip: false do

    RSpec.shared_examples 'data_sets_controller shared' do |dbg_verbose|
      before do
        described_class.data_sets_controller_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose

      end
      after do
        described_class.data_sets_controller_debug_verbose = debug_verbose
      end

      describe 'integration test for suppressed documents', skip: false do
        let(:work) do
          create(:data_set_work, :public, state: Vocab::FedoraResourceStatus.inactive)
        end

        before do
          create(:sipity_entity, proxy_for_global_id: work.to_global_id.to_s)
        end

        it 'renders only the title because it is in workflow' do
          get :show, params: { id: work }
          expect(response.code).to eq '200'
          # expect(response).to render_template(:unavailable)
          expect(assigns[:presenter]).to be_instance_of Hyrax::DataSetPresenter
          # expect(flash[:notice]).to eq 'The work is not currently available because it has not yet completed the approval process'
        end
      end

      describe 'integration test for depositor of a suppressed documents without a workflow role', skip: false do
        let(:work) do
          create(:data_set_work, :public, state: Vocab::FedoraResourceStatus.inactive, user: user)
        end

        before do
          create(:sipity_entity, proxy_for_global_id: work.to_global_id.to_s)
        end

        it 'renders without the unauthorized message' do
          get :show, params: { id: work.id }
          expect(response.code).to eq '200'
          expect(response).to render_template(:show)
          expect(assigns[:presenter]).to be_instance_of Hyrax::DataSetPresenter
          expect(flash[:notice]).to be_nil
        end
      end

      describe '#anonymous_link' do
        let(:work) do
          w = create(:data_set_with_one_file, user: user, depositor: user.email)
          w.depositor = user.email
          w
        end
        let(:anon_path)      { "/concern/data_sets/#{work.id}" }
        let(:anonymous_link) { AnonymousLink.create( item_id: work.id, path: anon_path ) }
        let(:anon_link_id)   { anonymous_link.download_key }

        before do
          create(:sipity_entity, proxy_for_global_id: work.to_global_id.to_s)
        end

        context 'while logged out' do
          # let(:work) { create(:public_data_set, user: user, title: ['public thing']) }

          before { sign_out user }

          context "without a referer" do

            before do
              expect(anonymous_link.valid?).to eq true
              expect(controller).to receive(:anonymous_link).and_call_original
              expect(controller).to receive(:ensure_curation_concern_exists).at_least(:once).and_call_original
              expect(controller).to receive(:anonymous_link_obj).with( link_id: anon_link_id ).at_least(:once).and_call_original
              expect(::Hyrax::AnonymousLinkService).to receive(:anonymous_link_valid?).with( anonymous_link,
                                                                          item_id: work.id,
                                                                          path: "/concern/data_sets/#{work.id}?locale=en" ).and_call_original
              expect(controller).to receive(:anonymous_link_destroy_because_invalid).with(anonymous_link).and_call_original
              expect(controller).to receive(:anonymous_link_destroy_because_tombstoned).with(anonymous_link).and_call_original
              expect(controller).to receive(:anonymous_link_destroy_because_published).with(anonymous_link).and_call_original
              expect(::Hyrax::AnonymousLinkService).to_not receive(:anonymous_link_destroy!)
              expect(controller).to receive(:presenter_init).and_call_original
            end

            it "shows the work" do
              expect(anonymous_link.valid?).to eq true
              get :anonymous_link, params: { id: work, anon_link_id: anon_link_id }
              expect(response).to be_successful
              ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
            end

          end

          context "with a referer", skip: true do
            before do
              request.env['HTTP_REFERER'] = 'http://test.host/foo'
            end

            it "sets breadcrumbs to authorized pages" do
              # TODO: expect(controller).to receive(:add_breadcrumb).with('Home', main_app.root_path(locale: 'en'))
              expect(controller).not_to receive(:add_breadcrumb).with('Dashboard', hyrax.dashboard_path(locale: 'en'))
              expect(controller).not_to receive(:add_breadcrumb).with('Your Works', hyrax.my_works_path(locale: 'en'))
              # TODO: expect(controller).to receive(:add_breadcrumb).with('public thing', main_app.hyrax_data_set_path(work.id, locale: 'en'))
              get :anonymous_link, params: { id: work, anon_link_id: anon_link_id }
              expect(response).to be_successful
              expect(response).to render_template("layouts/hyrax/1_column")
            end
          end
        end
      end

      describe '#ensure_doi_minted' do
        let(:work) do
          create(:data_set_work, :public, user: user)
        end

        before do
          create(:sipity_entity, proxy_for_global_id: work.to_global_id.to_s)
        end

        context 'as non-admin' do
          it 'calls job and redirects back' do
            allow(ActiveFedora::Base).to receive(:find).with(work.id).and_return(work)
            expect(::EnsureDoiMintedJob).to_not receive(:perform_later).with(id: work.id,
                                                                             current_user: user.email,
                                                                             email_results_to: user.email)
            get :ensure_doi_minted, params: { id: work }
            expect(response).to redirect_to(root_path)
            ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
          end
        end

        context 'as admin' do
          before do
            sign_out user
            sign_in admin
          end

          it 'calls job and redirects to main page' do
            allow(ActiveFedora::Base).to receive(:find).with(work.id).and_return(work)
            expect(::EnsureDoiMintedJob).to receive(:perform_later).with(id: work.id,
                                                                         current_user: admin.email,
                                                                         email_results_to: admin.email)
            get :ensure_doi_minted, params: { id: work }
            expect(response).to redirect_to main_app.hyrax_data_set_path(work.id, locale: 'en')
            expect(flash[:notice]).to eq "Ensure DOI minted job started. You will be emailed the results."
          end
        end
     end

      describe '#work_find_and_fix' do
        let(:work) do
          create(:data_set_work, :public, user: user)
        end

        before do
          create(:sipity_entity, proxy_for_global_id: work.to_global_id.to_s)
        end

        context 'as non-admin' do
          it 'calls job and redirects back' do
            allow(ActiveFedora::Base).to receive(:find).with(work.id).and_return(work)
            expect(::WorkFindAndFixJob).to_not receive(:perform_later).with(id: work.id, email_results_to: user.email)
            get :work_find_and_fix, params: { id: work }
            expect(response).to redirect_to(root_path)
            ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
          end
        end

        context 'as admin' do
          before do
            sign_out user
            sign_in admin
          end

          it 'calls job and redirects back' do
            allow(ActiveFedora::Base).to receive(:find).with(work.id).and_return(work)
            expect(::WorkFindAndFixJob).to receive(:perform_later).with(id: work.id, email_results_to: admin.email)
            get :work_find_and_fix, params: { id: work }
            expect(response).to redirect_to main_app.hyrax_data_set_path(work.id, locale: 'en')
            expect(flash[:notice]).to eq "Work find and fix job started. You will be emailed the results."
          end
        end

      end

    end

    it_behaves_like 'data_sets_controller shared', false
    it_behaves_like 'data_sets_controller shared', true

  end

  describe '#destroy', skip: false do
    let(:work_to_be_deleted) { create(:private_data_set, user: user) }
    let(:parent_collection) { build(:collection_lw) }

    it 'deletes the work' do
      delete :destroy, params: { id: work_to_be_deleted }
      expect(response).to redirect_to Hyrax::Engine.routes.url_helpers.my_works_path(locale: 'en')
      expect(DataSet).not_to exist(work_to_be_deleted.id)
    end

    context "when work is a member of a collection" do
      before do
        parent_collection.members = [work_to_be_deleted]
        parent_collection.save!
      end
      it 'deletes the work and updates the parent collection' do
        delete :destroy, params: { id: work_to_be_deleted }
        expect(DataSet).not_to exist(work_to_be_deleted.id)
        expect(response).to redirect_to Hyrax::Engine.routes.url_helpers.my_works_path(locale: 'en')
        expect(parent_collection.reload.members).to eq []
      end
    end

    it "invokes the after_destroy callback" do
      expect(Hyrax.config.callback).to receive(:run)
                                         .with(:after_destroy, work_to_be_deleted.id, user)
      delete :destroy, params: { id: work_to_be_deleted }
    end

    context 'someone elses public work' do
      let(:work_to_be_deleted) { create(:private_data_set) }

      it 'shows unauthorized message' do
        delete :destroy, params: { id: work_to_be_deleted }
        expect(response.code).to eq '401'
        expect(response).to render_template(:unauthorized)
      end
    end

    context 'when I am a repository manager' do
      let(:work_to_be_deleted) { create(:private_data_set) }

      before { allow(::User.group_service).to receive(:byname).and_return(user.user_key => ['admin']) }
      it 'someone elses private work should delete the work' do
        delete :destroy, params: { id: work_to_be_deleted }
        expect(DataSet).not_to exist(work_to_be_deleted.id)
      end
    end
  end

  describe '#doi', skip: false do
    let(:expected_mint_msg) { "The expected mint message." }

    # see doi_controller_behavior.rb
    before do
      create(:sipity_entity, proxy_for_global_id: work.to_global_id.to_s)
    end

    context 'work without doi' do
      let(:work) do
        w = create(:data_set_with_one_file, user: user, depositor: user.email, doi: nil)
        w.depositor = user.email
        w
      end

      it 'redirects' do
        # expect(controller).to receive(:doi_mint)
        allow(ActiveFedora::Base).to receive(:find).with(work.id).and_return(work)
        expect(controller).to receive(:doi_mint).and_return expected_mint_msg
        # expect(work).to receive(:doi_mint).with( current_user: user, event_note: DataSet.class.name )
        get :doi, params: { id: work }
        expect(response).to redirect_to main_app.hyrax_data_set_path(work, locale: 'en')
        expect(flash[:notice]).to eq expected_mint_msg
      end

    end

    context 'private work pending doi', skip: true do
      let(:work) { create(:private_data_set, user: user, title: ['test title'], doi: ::Deepblue::DoiBehavior.doi_pending_init ) }

      it 'redirects' do
        allow(ActiveFedora::Base).to receive(:find).with(work.id).and_return(work)
        expect(controller).to receive(:doi_mint).and_return expected_mint_msg
        # expect(work).to_not receive(:doi_mint).with( current_user: user, event_note: DataSet.class.name )
        get :doi, params: { id: work }
        expect(response).to redirect_to main_app.hyrax_data_set_path(work, locale: 'en')
      end

    end

  end

  describe '#new', skip: false do
    context 'my work' do
      it 'shows me the page' do
        get :new
        expect(response).to be_successful
        expect(assigns[:form]).to be_kind_of Hyrax::DataSetForm
        expect(assigns[:form].depositor).to eq user.user_key
        expect(assigns[:curation_concern]).to be_kind_of DataSet
        expect(assigns[:curation_concern].depositor).to eq user.user_key
        expect(response).to render_template("layouts/hyrax/dashboard")
      end
    end
  end

  describe '#create', skip: false do
    let(:actor) { double(create: create_status) }
    let(:create_status) { true }

    before do
      allow(Hyrax::CurationConcern).to receive(:actor).and_return(actor)
    end

    context 'when create is successful' do
      let(:work) { stub_model(DataSet) }
      let(:admin_set) { instance_double( AdminSet, id: 'admin_set_id' ) }

      it 'creates a work' do
        allow(controller).to receive(:curation_concern).and_return(work)
        allow(work).to receive(:admin_set).and_return admin_set
        allow(admin_set).to receive(:title).and_return ["AdminSet"]
        post :create, params: { data_set: { title: ['a title'] } }
        expect(response).to redirect_to main_app.hyrax_data_set_path(work, locale: 'en')
      end
    end

    context 'when create fails' do
      let(:work) { create(:data_set_work) }
      let(:create_status) { false }

      it 'draws the form again' do
        post :create, params: { data_set: { title: ['a title'] } }
        expect(response.status).to eq 422
        expect(assigns[:form]).to be_kind_of Hyrax::DataSetForm
        expect(response).to render_template 'new'
      end
    end

    context 'when not authorized' do
      before { allow(controller.current_ability).to receive(:can?).and_return(false) }

      it 'shows the unauthorized message' do
        post :create, params: { data_set: { title: ['a title'] } }
        expect(response.code).to eq '401'
        expect(response).to render_template(:unauthorized)
      end
    end

    context "with files" do
      let(:actor) { double('An actor') }
      let(:work) { create(:data_set_work) }
      let(:admin_set) { instance_double( AdminSet, id: 'admin_set_id' ) }

      before do
        allow(controller).to receive(:actor).and_return(actor)
        # Stub out the creation of the work so we can redirect somewhere
        allow(controller).to receive(:curation_concern).and_return(work)
      end

      it "attaches files" do
        allow(work).to receive(:admin_set).and_return admin_set
        allow(admin_set).to receive(:title).and_return ["AdminSet"]

        expect(actor).to receive(:create)
                             .with(Hyrax::Actors::Environment) do |env|
          expect(env.attributes.keys).to include('uploaded_files')
        end
            .and_return(true)
        post :create, params: {
            data_set: {
                title: ["First title"],
                visibility: 'open'
            },
            uploaded_files: ['777', '888']
        }

        expect(flash[:notice]).to be_html_safe
        expect(flash[:notice]).to eq "Your files are being processed by Deep Blue Data in the background. " \
                                     "The metadata and access controls you specified are being applied. " \
                                     "You may need to refresh this page to see these updates."
        expect(response).to redirect_to main_app.hyrax_data_set_path(work, locale: 'en')
      end

      context "from browse everything" do
        let(:url1) { "https://dl.dropbox.com/fake/blah-blah.filepicker-demo.txt.txt" }
        let(:url2) { "https://dl.dropbox.com/fake/blah-blah.Getting%20Started.pdf" }
        let(:browse_everything_params) do
          { "0" => { "url" => url1,
                     "expires" => "2014-03-31T20:37:36.214Z",
                     "file_name" => "filepicker-demo.txt.txt" },
            "1" => { "url" => url2,
                     "expires" => "2014-03-31T20:37:36.731Z",
                     "file_name" => "Getting+Started.pdf" } }.with_indifferent_access
        end
        let(:uploaded_files) do
          browse_everything_params.values.map { |v| v['url'] }
        end

        context "For a batch upload" do
          # TODO: move this to batch_uploads controller
          it "ingests files from provide URLs" do
            skip "Creating a FileSet without a parent work is not yet supported"
            expect(ImportUrlJob).to receive(:perform_later).twice
            expect do
              post :create, params: { selected_files: browse_everything_params, file_set: {} }
            end.to change(FileSet, :count).by(2)
            created_files = FileSet.all
            expect(created_files.map(&:import_url)).to include(url1, url2)
            expect(created_files.map(&:label)).to include("filepicker-demo.txt.txt", "Getting+Started.pdf")
          end
        end

        context "when a work id is passed" do
          let(:work) do
            create(:data_set_work, user: user, title: ['test title'])
          end
          let(:admin_set) { instance_double( AdminSet, id: 'admin_set_id' ) }

          it "records the work" do
            allow(work).to receive(:admin_set).and_return admin_set
            allow(admin_set).to receive(:title).and_return ["AdminSet"]

            # TODO: ensure the actor stack, called with these params
            # makes one work, two file sets and calls ImportUrlJob twice.
            expect(actor).to receive(:create).with(Hyrax::Actors::Environment) do |env|
              expect(env.attributes['uploaded_files']).to eq []
              expect(env.attributes['remote_files']).to eq browse_everything_params.values
            end

            post :create, params: {
                selected_files: browse_everything_params,
                uploaded_files: uploaded_files,
                parent_id: work.id,
                data_set: { title: ['First title'] }
            }
            expect(flash[:notice]).to eq "Your files are being processed by Deep Blue Data in the background. " \
                                         "The metadata and access controls you specified are being applied. " \
                                         "You may need to refresh this page to see these updates."
            expect(response).to redirect_to main_app.hyrax_data_set_path(work, locale: 'en')
          end
        end
      end
    end
  end

  describe '#edit', skip: false do

    context 'my own private work', skip: false do
      let(:work) { create(:private_data_set, user: user) }

      it 'shows me the page and sets breadcrumbs' do
        # no breadcrumbs on edit form
        # expect(controller).to receive(:add_breadcrumb).with("Home", root_path(locale: 'en'))
        # expect(controller).to receive(:add_breadcrumb).with("Dashboard", hyrax.dashboard_path(locale: 'en'))
        # expect(controller).to receive(:add_breadcrumb).with("Works", hyrax.my_works_path(locale: 'en'))
        # expect(controller).to receive(:add_breadcrumb).with(work.title.first, main_app.hyrax_data_set_path(work.id, locale: 'en'))
        # expect(controller).to receive(:add_breadcrumb).with('Edit', main_app.edit_hyrax_data_set_path(work.id))

        get :edit, params: { id: work }
        expect(response).to be_successful
        expect(assigns[:form]).to be_kind_of Hyrax::DataSetForm
        expect(response).to render_template("layouts/hyrax/dashboard")
      end
    end

    context 'someone elses private work', skip: false do
      routes { Rails.application.class.routes }
      let(:work) { create(:private_data_set, user: user_other) }

      it 'shows the unauthorized message' do
        get :edit, params: { id: work }
        expect(response.code).to eq '401'
        expect(response).to render_template(:unauthorized)
      end
    end

    context 'someone elses public work', skip: false do
      let(:work) { create(:public_data_set, user: user_other) }

      it 'shows the unauthorized message' do
        get :edit, params: { id: work }
        expect(response.code).to eq '401'
        expect(response).to render_template(:unauthorized)
      end
    end

    context 'someone elses public work and have edit access', skip: false do
      let(:work) { create(:public_data_set, user: user_other, edit_users: [user.email]) }

      it 'can edit' do
        # puts
        # puts "user.email=#{user.email}"
        # puts "user_other.email=#{user_other.email}"
        # puts
        get :edit, params: { id: work }
        # expect(response.code).to eq '401'
        expect(response).to be_successful
        expect(flash[:notice]).not_to eq 'The work is not currently available because it has not yet completed the approval process'
      end
    end

    context 'when I am a repository manager', skip: false do
      before { allow(::User.group_service).to receive(:byname).and_return(user.user_key => ['admin']) }
      let(:work) { create(:private_data_set) }

      it 'someone elses private work should show me the page' do
        get :edit, params: { id: work }
        expect(response).to be_successful
      end
    end
  end

  describe '#show', skip: false do
    RSpec.shared_examples 'shared #show' do |dbg_verbose|
      subject { described_class }
      before do
        described_class.data_sets_controller_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose
      end
      after do
        described_class.data_sets_controller_debug_verbose = debug_verbose
      end
      context do
        before do
          create(:sipity_entity, proxy_for_global_id: work.to_global_id.to_s)
        end

        context 'while logged out' do
          let(:work) { create(:public_data_set, user: user, title: ['public thing']) }

          before { sign_out user }

          context "without a referer" do
            it "sets the default breadcrumbs" do
              # TODO: expect(controller).to receive(:add_breadcrumb).with('Home', Hyrax::Engine.routes.url_helpers.root_path(locale: 'en'))
              get :show, params: { id: work }
              expect(response).to be_successful
            end
          end

          context "with a referer" do
            before do
              request.env['HTTP_REFERER'] = 'http://test.host/foo'
            end

            it "sets breadcrumbs to authorized pages" do
              # TODO: expect(controller).to receive(:add_breadcrumb).with('Home', main_app.root_path(locale: 'en'))
              expect(controller).not_to receive(:add_breadcrumb).with('Dashboard', hyrax.dashboard_path(locale: 'en'))
              expect(controller).not_to receive(:add_breadcrumb).with('Your Works', hyrax.my_works_path(locale: 'en'))
              # TODO: expect(controller).to receive(:add_breadcrumb).with('public thing', main_app.hyrax_data_set_path(work.id, locale: 'en'))
              get :show, params: { id: work }
              expect(response).to be_successful
              expect(response).to render_template("layouts/hyrax/1_column")
            end
          end
        end

        context 'my own private work' do
          let(:work) { create(:private_data_set, user: user, title: ['test title']) }

          it 'shows me the page' do
            get :show, params: { id: work }
            expect(response).to be_successful
            expect(assigns(:presenter)).to be_kind_of Hyrax::WorkShowPresenter
          end

          context "without a referer" do
            it "sets breadcrumbs" do
              # TODO: expect(controller).to receive(:add_breadcrumb).with('Home', Hyrax::Engine.routes.url_helpers.root_path(locale: 'en'))
              # TODO: expect(controller).to receive(:add_breadcrumb).with("Dashboard", hyrax.dashboard_path(locale: 'en'))
              get :show, params: { id: work }
              expect(response).to be_successful
            end
          end

          context "with a referer", skip: true do
            before do
              request.env['HTTP_REFERER'] = 'http://test.host/foo'
            end

            it "sets breadcrumbs" do
              expect(controller).to receive(:add_breadcrumb).with('Home', Hyrax::Engine.routes.url_helpers.root_path(locale: 'en'))
              expect(controller).to receive(:add_breadcrumb).with('Dashboard', hyrax.dashboard_path(locale: 'en'))
              expect(controller).to receive(:add_breadcrumb).with('Works', hyrax.my_works_path(locale: 'en'))
              expect(controller).to receive(:add_breadcrumb).with('test title', main_app.hyrax_data_set_path(work.id, locale: 'en'))
              get :show, params: { id: work }
              expect(response).to be_successful
              expect(response).to render_template("layouts/hyrax/1_column")
            end
          end

          context "with a parent work" do
            let(:parent) { create(:data_set_work, title: ['Parent Work'], user: user, ordered_members: [work]) }

            before do
              create(:sipity_entity, proxy_for_global_id: parent.to_global_id.to_s)
            end

            it "sets the parent presenter" do
              get :show, params: { id: work, parent_id: parent }
              expect(response).to be_successful
              expect(assigns[:parent_presenter]).to be_instance_of Hyrax::DataSetPresenter
            end
          end

          context "with an endnote file" do
            let(:disposition)  { response.header.fetch("Content-Disposition") }
            let(:content_type) { response.header.fetch("Content-Type") }

            render_views

            it 'downloads the file' do
              get :show, params: { id: work, format: 'endnote' }
              expect(response).to be_successful
              expect(disposition).to include("attachment")
              expect(content_type).to eq("application/x-endnote-refer")
              expect(response.body).to include("%T test title")
            end
          end
        end

        context 'someone elses private work' do
          let(:work) { create(:private_data_set) }

          it 'shows unauthorized message' do
            get :show, params: { id: work }
            expect(response.code).to eq '200'
            # TODO:
            # expect(response).to render_template(:unauthorized)
          end
        end

        context 'someone else\'s public work' do
          let(:work) { create(:public_data_set) }

          context "html" do
            it 'shows me the page' do
              expect(controller). to receive(:additional_response_formats).with(ActionController::MimeResponds::Collector)
              get :show, params: { id: work }
              expect(response).to be_successful
            end
          end

          context "ttl" do
            let(:presenter) { double }

            before do
              allow(controller).to receive(:presenter).and_return(presenter)
              allow(presenter).to receive(:export_as_ttl).and_return("ttl graph")
              allow(presenter).to receive(:editor?).and_return(true)
            end

            # TODO: fix
            it 'renders a turtle file', skip: true do
              get :show, params: { id: '99999999', format: :ttl }

              expect(response).to be_successful
              expect(response.body).to eq "ttl graph"
              expect(response.content_type).to eq 'text/turtle'
            end
          end
        end

        context 'when I am a repository manager' do
          before { allow(::User.group_service).to receive(:byname).and_return(user.user_key => ['admin']) }
          let(:work) { create(:private_data_set) }

          it 'someone elses private work should show me the page' do
            get :show, params: { id: work }
            expect(response).to be_successful
          end
        end

        context 'with work still in workflow' do
          before do
            allow(controller).to receive(:search_results).and_return([nil, document_list])
          end
          let(:work) { instance_double(DataSet, id: '99999', to_global_id: '99999') }

          context 'with a user lacking both workflow permission and read access' do
            before do
              allow(SolrDocument).to receive(:find).and_return(document)
              allow(controller.current_ability).to receive(:can?).with(:read, document).and_return(false)
            end
            let(:document_list) { [] }
            let(:document) { instance_double(SolrDocument, suppressed?: true) }

            it 'shows the unauthorized message' do
              get :show, params: { id: work.id }
              expect(response.code).to eq '401'
              expect(response).to render_template(:unauthorized)
              ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
            end

            context 'with a user who lacks workflow permission but has read access' do
              before do
                allow(SolrDocument).to receive(:find).and_return(document)
                allow(controller.current_ability).to receive(:can?).with(:read, document).and_return(true)
              end
              let(:document_list) { [] }
              let(:document) { instance_double(SolrDocument, suppressed?: true) }

              it 'shows the unavailable message' do
                get :show, params: { id: work.id }
                expect(response.code).to eq '401'
                expect(response).to render_template(:unavailable)
                expect(flash[:notice]).to eq 'The work is not currently available because it has not yet completed the approval process'
                ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
              end
            end
          end

          context 'with a user granted workflow permission', skip: true do
            # TODO: fix this for hyrax v3
            let(:document_list) { [document] }
            let(:document) { instance_double(SolrDocument) }
            before do
              allow(document).to receive(:[]).and_return(nil)
              allow(controller).to receive(:read_me_file_set).and_return("this should be a file set")
            end

            it 'renders without the unauthorized message' do
              get :show, params: { id: work.id }
              expect(response.code).to eq '200'
              expect(response).to render_template(:show)
              expect(flash[:notice]).to be_nil
            end
          end
        end
      end
    end
    it_behaves_like 'shared #show', false
    it_behaves_like 'shared #show', true
  end

  describe '#update', skip: false do
    let(:work) { stub_model(DataSet) }
    let(:visibility_changed) { false }
    let(:actor) { double(update: true) }

    before do
      allow(Hyrax::CurationConcern).to receive(:actor).and_return(actor)
      allow(DataSet).to receive(:find).and_return(work)
      allow(work).to receive(:visibility_changed?).and_return(visibility_changed)
    end

    context "when the user has write access to the file" do
      before do
        allow(controller).to receive(:authorize!).with(:update, work).and_return(true)
        allow(controller.current_ability).to receive(:can?).with(:edit, work.id).and_return(true)
      end
      context "when the work has no file sets" do
        it 'updates the work' do
          patch :update, params: { id: work, data_set: { title: ['First Title'] } }
          expect(response).to redirect_to main_app.hyrax_data_set_path(work, locale: 'en')
        end
      end

      context "when the work has file sets attached" do
        before do
          allow(work).to receive(:file_sets).and_return(double(present?: true))
          allow(controller.current_ability).to receive(:can?).with(:edit, work.id).and_return(true)
        end
        it 'updates the work' do
          patch :update, params: { id: work, data_set: { title: ['First Title'] } }
          expect(response).to redirect_to main_app.hyrax_data_set_path(work, locale: 'en')
        end
      end

      it "can update file membership" do
        patch :update, params: { id: work, data_set: { ordered_member_ids: ['foo_123'] } }
        expect(actor).to have_received(:update).with(Hyrax::Actors::Environment) do |env|
          expect(env.attributes).to eq("date_coverage"=>nil,
                                       "ordered_member_ids" => ['foo_123'],
                                       "remote_files" => [],
                                       "uploaded_files" => [])
        end
      end

      describe 'changing rights' do
        let(:visibility_changed) { true }
        let(:actor) { double(update: true) }

        context 'when the work has file sets attached' do
          before do
            allow(work).to receive(:file_sets).and_return(double(present?: true))
            allow(controller.current_ability).to receive(:can?).with(:edit, work.id).and_return(true)
          end
          it 'prompts to change the files access' do
            patch :update, params: { id: work, data_set: { title: ['First Title'] } }
            expect(response).to redirect_to main_app.confirm_hyrax_permission_path(controller.curation_concern, locale: 'en')
          end
        end

        context 'when the work has no file sets' do
          it "doesn't prompt to change the files access" do
            patch :update, params: { id: work, data_set: { title: ['First Title'] } }
            expect(response).to redirect_to main_app.hyrax_data_set_path(work, locale: 'en')
          end
        end
      end

      describe 'update failed' do
        let(:actor) { double(update: false) }

        it 'renders the form' do
          patch :update, params: { id: work, data_set: { title: ['First Title'] } }
          expect(assigns[:form]).to be_kind_of Hyrax::DataSetForm
          expect(response).to render_template('edit')
        end
      end
    end

    context 'someone elses public work' do
      let(:work) { create(:public_data_set) }

      it 'shows the unauthorized message' do
        get :update, params: { id: work, data_set: { title: ['First Title'] } }
        expect(response.code).to eq '401'
        expect(response).to render_template(:unauthorized)
      end
    end

    context 'when I am a repository manager' do
      before { allow(::User.group_service).to receive(:byname).and_return(user.user_key => ['admin']) }

      let(:work) { create(:private_data_set) }

      it 'someone elses private work should update the work' do
        patch :update, params: { id: work, data_set: { title: ['First Title'] } }
        expect(response).to redirect_to main_app.hyrax_data_set_path(work, locale: 'en')
      end
    end
  end

  describe '#file_manager', skip: false do
    let(:work) { create(:private_data_set, user: user) }

    before do
      create(:sipity_entity, proxy_for_global_id: work.to_global_id.to_s)
    end

    it "is successful" do
      get :file_manager, params: { id: work.id }
      expect(response).to be_successful
      expect(assigns(:form)).not_to be_blank
    end

  end

  describe '#item_identifier', skip: false do
    let(:work) { create(:public_data_set) }

    before do
      create(:sipity_entity, proxy_for_global_id: work.to_global_id.to_s)
    end

    it "returns an oai identifier" do
      get :show, params: { id: work }
      expect(response).to be_successful
      expect(controller.item_identifier_for_irus_analytics).to eq "oai:deepbluedata:#{work.id}"
    end

  end


  describe '#zip_download', skip: false do
    let(:work) { create(:data_set_with_two_children, total_file_size: 1.kilobyte, user: user) }

    before do
      create(:sipity_entity, proxy_for_global_id: work.to_global_id.to_s)
    end

    RSpec.shared_examples 'it calls zip_download' do |dbg_verbose|

      context 'downloads' do

        before do
          if dbg_verbose
            expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once)
          else
            expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug)
          end
          allow(ActiveFedora::Base).to receive(:find).with(work.id).and_return(work)
        end

        it 'for total file size downloadable' do
          save_debug_verbose = ::Deepblue::ZipDownloadControllerBehavior.zip_download_controller_behavior_debug_verbose
          ::Deepblue::ZipDownloadControllerBehavior.zip_download_controller_behavior_debug_verbose = dbg_verbose
          expect(work).to receive(:total_file_size).and_call_original
          expect(::Deepblue::ZipDownloadService).to receive(:zip_download_max_total_file_size_to_download).and_call_original
          expect(controller).to receive(:zip_download_rest).with(curation_concern: work)
          expect(controller).to receive(:report_irus_analytics_request).and_call_original
          expect(::Deepblue::IrusHelper).to receive(:log) do |args|
            expect( args[:event] ).to eq "analytics_request"
          end

          # expect(controller).to receive(:item_identifier).and_call_original
          # expect(controller).to receive(:skip_send_irus_analytics?).with('Request').and_call_original
          # expect(controller).to receive(:deposited?).and_return true
          expect(controller).to receive(:send_irus_analytics).with(nil, "Request").at_least(:once)

          post :zip_download, params: { id: work }
          ::Deepblue::ZipDownloadControllerBehavior.zip_download_controller_behavior_debug_verbose = save_debug_verbose
        end

      end

      context 'no download' do

        before do
          if dbg_verbose
            expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once)
          else
            expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug)
          end
          allow(ActiveFedora::Base).to receive(:find).with(work.id).and_return(work)
        end

        it 'for total file size downloadable larger than permitted' do
          save_debug_verbose = ::Deepblue::ZipDownloadControllerBehavior.zip_download_controller_behavior_debug_verbose
          ::Deepblue::ZipDownloadControllerBehavior.zip_download_controller_behavior_debug_verbose = dbg_verbose
          expect(work).to receive(:total_file_size).and_call_original
          expect(::Deepblue::ZipDownloadService).to receive(:zip_download_max_total_file_size_to_download).and_return 1
          expect(controller).not_to receive(:zip_download_rest).with(curation_concern: work)
          expect { post :zip_download, params: { id: work } }.to raise_error ActiveFedora::IllegalOperation
          ::Deepblue::ZipDownloadControllerBehavior.zip_download_controller_behavior_debug_verbose = save_debug_verbose
        end

      end

    end

    context 'calls zip_download_rest' do

      it_behaves_like 'it calls zip_download', false
      it_behaves_like 'it calls zip_download', true

    end

  end

  # TODO: reactivate when using IIIF
  describe '#manifest', skip: true do
    let(:work) { create(:data_set_with_one_file, user: user) }
    let(:file_set) { work.ordered_members.to_a.first }
    let(:manifest_factory) { double(to_h: { test: 'manifest' }) }

    before do
      Hydra::Works::AddFileToFileSet.call(file_set,
                                          File.open(fixture_path + '/world.png'),
                                          :original_file)
      allow(IIIFManifest::ManifestFactory).to receive(:new)
        .with(Hyrax::IiifManifestPresenter)
        .and_return(manifest_factory)
    end

    it 'uses the configured service' do
      custom_builder = double(manifest_for: { test: 'cached manifest' })
      allow(described_class).to receive(:iiif_manifest_builder).and_return(custom_builder)

      get :manifest, params: { id: work, format: :json }
      expect(response.body).to eq "{\"test\":\"cached manifest\"}"
    end

    it "produces a manifest for a json request" do
      get :manifest, params: { id: work, format: :json }
      expect(response.body).to eq "{\"test\":\"manifest\"}"
    end

    it "produces a manifest for a html request" do
      get :manifest, params: { id: work, format: :html }
      expect(response.body).to eq "{\"test\":\"manifest\"}"
    end
  end

  describe 'private methods', skip: false do

    context '.get_date_uploaded_from_solr', skip: true do

    end

    context '.target_dir_name_id', skip: false do
      let(:dir) { Pathname.new "/test/testing" }
      let(:id)  { "abc123" }
      let(:ext) { '.txt' }

      it 'returns correct value with ext' do
        expect(controller.send(:target_dir_name_id,dir,id,ext).to_s).to eq '/test/testing/abc123.txt'
      end

      it 'returns correct value without ext' do
        expect(controller.send(:target_dir_name_id,dir,id).to_s).to eq '/test/testing/abc123'
      end

    end

  end

end
