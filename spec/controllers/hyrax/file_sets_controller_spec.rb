require 'rails_helper'

RSpec.describe Hyrax::FileSetsController, :clean_repo do

  include Devise::Test::ControllerHelpers
  routes { Rails.application.routes }

  let(:main_app) { Rails.application.routes.url_helpers }

  let(:debug_verbose) { false }

  let(:user)     { create(:user) }
  let(:actor)    { controller.send(:actor) }
  let(:not_authorized) { I18n.t(:"unauthorized.default", default: 'You are not authorized to access this page.') }

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.file_sets_controller_debug_verbose ).to eq( false )
      expect( ::Hyrax::AnonymousLinkService.anonymous_link_service_debug_verbose ).to eq( debug_verbose )
    end
  end

  RSpec.shared_examples 'Not anonymous link' do
    it { expect(controller.anonymous_link_request?).to eq false }
    it { expect(controller.anonymous_show?).to eq false }
  end

  RSpec.shared_examples 'it requires login' do
    let(:flash_msg) { "You need to sign in or sign up before continuing." }
    # let(:flash_msg) { I18n.t('devise.failure.unauthenticated') }
    # let(:flash_msg) { I18n.t(:"unauthorized.default", default: 'You are not authorized to access this page.') }
    it 'requires login' do
      expect(controller.anonymous_link?).to eq false
      expect(response).to_not be_nil
      # expect(response).to fail_redirect_and_flash(main_app.new_user_session_path, flash_msg)
      expect(response.status).to eq 302
      expect(response).to redirect_to(main_app.new_user_session_path)
      expect(flash[:alert]).to eq flash_msg
    end
  end

  RSpec.shared_examples 'it is successful' do
    it 'successful' do
      expect(controller.anonymous_link?).to eq false
      expect(response).to_not be_nil
      expect(response.status).to eq 200
    end
  end

  RSpec.shared_examples 'it is successful anonymous' do
    it 'successful' do
      expect(controller.anonymous_link?).to eq true
      expect(response).to_not be_nil
      expect(response.status).to eq 200
    end
  end

  describe 'unknown user' do
    RSpec.shared_examples 'shared when not signed in' do |dbg_verbose|
      before do
        described_class.file_sets_controller_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose
      end
      after do
        described_class.file_sets_controller_debug_verbose = debug_verbose
      end
      context 'when not signed in' do
        let(:private_file_set) { create(:file_set) }
        let(:public_file_set)  { create(:file_set, read_groups: ['public']) }

        describe '#edit' do
          before { get :edit, params: { id: public_file_set } }
          it_behaves_like 'it requires login'
        end

        describe '#show' do
          context 'denies access to private files' do
            before { get :show, params: { id: private_file_set } }
            it { expect(response).to redirect_to main_app.new_user_session_path(locale: 'en') }
          end

          context 'allows access to public files' do
            before do
              expect(controller).to receive(:additional_response_formats).with(ActionController::MimeResponds::Collector)
              get :show, params: { id: public_file_set }
            end
            it_behaves_like 'it is successful'
          end
        end

      end
    end
    it_behaves_like 'shared when not signed in', false
    # it_behaves_like 'shared when not signed in', true # no debug statements to trigger
  end

  describe 'when signed in' do
    RSpec.shared_examples 'shared when signed in' do |dbg_verbose|
      subject { described_class }
      before do
        described_class.file_sets_controller_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose
      end
      after do
        described_class.file_sets_controller_debug_verbose = debug_verbose
      end
      context do
        before do
          sign_in user
        end

        describe "#destroy" do
          context "file_set with a parent" do
            let(:file_set) do
              create(:file_set, user: user)
            end
            let(:work) do
              create( :data_set_work,
                      creator: [ "Dr. Creator" ],
                      rights_license: "The Rights License",
                      title: ['test title'],
                      user: user )
            end

            let(:delete_message) { double('delete message') }

            before do
              work.ordered_members << file_set
              work.save!
            end

            it "deletes the file" do
              expect(ContentDeleteEventJob).to receive(:perform_later).with(file_set.id, user)
              expect do
                delete :destroy, params: { id: file_set }
              end.to change { FileSet.exists?(file_set.id) }.from(true).to(false)
              expect(response).to redirect_to main_app.hyrax_data_set_path(work, locale: 'en')
              expect(controller.anonymous_link_request?).to eq false
              expect(controller.anonymous_link_request?).to eq false
              expect(controller.anonymous_show?).to eq false
            end
          end
        end

        describe "#edit" do
          let(:parent) do
            create( :data_set_work,
                    :public,
                    creator: [ "Dr. Creator" ],
                    rights_license: "The Rights License",
                    title: ['test title'],
                    user: user )
          end
          let(:file_set) do
            create(:file_set, user: user).tap do |file_set|
              parent.ordered_members << file_set
              parent.save!
            end
          end

          before do
            binary = StringIO.new("hey")
            Hydra::Works::AddFileToFileSet.call_enhanced_version(file_set, binary, :original_file, versioning: true)
            request.env['HTTP_REFERER'] = 'http://test.host/foo'
          end

          it "sets the breadcrumbs and versions presenter" do
            expect(controller).to receive(:add_breadcrumb).with('Home',
                                                                Hyrax::Engine.routes.url_helpers.root_path(locale: 'en'))
            expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.title'),
                                                                Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
            expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.my.works'),
                                                                Hyrax::Engine.routes.url_helpers.my_works_path(locale: 'en'))
            expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.file_set.browse_view'),
                                                                Rails.application.routes.
                                                                  url_helpers.hyrax_file_set_path(file_set, locale: 'en'))
            get :edit, params: { id: file_set }

            expect(response).to be_success
            expect(assigns[:file_set]).to eq file_set
            expect(assigns[:version_list]).to be_kind_of Hyrax::VersionListPresenter
            expect(assigns[:parent]).to eq parent
            expect(response).to render_template(:edit)
            expect(response).to render_template('dashboard')
            expect(controller.anonymous_link_request?).to eq false
            expect(controller.anonymous_show?).to eq false
          end
        end

        describe "#update" do
          let(:file_set) do
            create(:file_set, user: user)
          end

          context "when updating metadata" do
            it "spawns a content update event job" do
              expect(ContentUpdateEventJob).to receive(:perform_later).with(file_set, user)
              post :update, params: {
                id: file_set,
                file_set: {
                  title: ['new_title'],
                  keyword: [''],
                  permissions_attributes: [{ type: 'person',
                                             name: 'archivist1',
                                             access: 'edit' }]
                }
              }
              expect(response).to redirect_to main_app.hyrax_file_set_path(file_set, locale: 'en')
            end
          end

          context "when updating the attached file", skip: true do
            let(:actor) { double }

            before do
              allow(Hyrax::Actors::FileActor).to receive(:new).and_return(actor)
            end

            it "spawns a ContentNewVersionEventJob", perform_enqueued: [IngestJob] do
              expect(ContentNewVersionEventJob).to receive(:perform_later).with(file_set, user)
              expect(actor).to receive(:ingest_file).with(JobIoWrapper).and_return(true)
              file = fixture_file_upload('/world.png', 'image/png')
              post :update, params: { id: file_set,
                                      filedata: file,
                                      file_set: { keyword: [''],
                                                  permissions_attributes: [{ type: 'person',
                                                                             name: 'archivist1',
                                                                             access: 'edit' }] } }
              # this fails because the file_set.current_version is nil, don't know how to fix that for now
              post :update, params: { id: file_set,
                                      file_set: { files: [file],
                                                  keyword: [''],
                                                  permissions_attributes: [{ type: 'person',
                                                                             name: 'archivist1',
                                                                             access: 'edit' }] } }
            end
          end

          context "with two existing versions from different users", :perform_enqueued do
            let(:file1)       { "world.png" }
            let(:file2)       { "image.jpg" }
            let(:second_user) { create(:user) }
            let(:version1)    { "version1" }
            let(:actor1)      { Hyrax::Actors::FileSetActor.new(file_set, user) }
            let(:actor2)      { Hyrax::Actors::FileSetActor.new(file_set, second_user) }

            let( :job )          { TestJob.send( :job_or_instantiate ) }
            let( :job_id )       { job.job_id }
            let(:job_status_var) { JobStatus.create( job_id: job_id, job_class: job.class ) }
            let(:job_status)     { IngestJobStatus.new( job_status: job_status_var,
                                                        verbose: false,
                                                        main_cc_id: nil,
                                                        user_id: user.id  ) }

            before do
              ActiveJob::Base.queue_adapter.filter = [IngestJob]
              actor1.create_content(fixture_file_upload(file1), job_status: job_status, continue_job_chain_later: false)
              actor2.create_content(fixture_file_upload(file2), job_status: job_status, continue_job_chain_later: false)
            end

            describe "restoring a previous version", skip: true do
              context "as the first user" do
                before do
                  sign_in user
                  post :update, params: { id: file_set, revision: version1 }
                end

                let(:restored_content) { file_set.reload.original_file }
                let(:versions)         { restored_content.versions }
                let(:latest_version)   { Hyrax::VersioningService.latest_version_of(restored_content) }

                it "restores the first versions's content and metadata" do
                  # expect(restored_content.mime_type).to eq "image/png"
                  expect(restored_content).to be_a(Hydra::PCDM::File)
                  expect(restored_content.original_name).to eq file1
                  # expect(versions.all.count).to eq 3
                  expect(versions.last.label).to eq latest_version.label
                  expect(Hyrax::VersionCommitter.where(version_id: versions.last.uri).
                    pluck(:committer_login)).to eq [user.user_key]
                  # TODO: this returns 1
                  expect(versions.all.count).to eq 3
                end
              end

              context "as a user without edit access" do
                before do
                  sign_in second_user
                end

                it "is unauthorized" do
                  post :update, params: { id: file_set, revision: version1 }
                  expect(response.code).to eq '401'
                  expect(response).to render_template 'unauthorized'
                  expect(response).to render_template('dashboard')
                end
              end
            end
          end

          it "adds new groups and users" do
            post :update, params: {
              id: file_set,
              file_set: { keyword: [''],
                          permissions_attributes: [
                            { type: 'person', name: 'user1', access: 'edit' },
                            { type: 'group', name: 'group1', access: 'read' }
                          ] }
            }

            expect(assigns[:file_set].read_groups).to eq ["group1"]
            expect(assigns[:file_set].edit_users).to include("user1", user.user_key)
          end

          it "updates existing groups and users" do
            file_set.edit_groups = ['group3']
            file_set.save
            post :update, params: {
              id: file_set,
              file_set: { keyword: [''],
                          permissions_attributes: [
                            { id: file_set.permissions.last.id, type: 'group', name: 'group3', access: 'read' }
                          ] }
            }

            expect(assigns[:file_set].read_groups).to eq(["group3"])
          end

          context "when there's an error saving" do
            let(:file_set) do
              create(:file_set, user: user)
            end

            before do
              allow(FileSet).to receive(:find).and_return(file_set)
            end
            it "draws the edit page" do
              expect(file_set).to receive(:valid?).and_return(false)
              post :update, params: { id: file_set, file_set: { keyword: [''] } }
              expect(response.code).to eq '422'
              expect(response).to render_template('edit')
              expect(response).to render_template('dashboard')
              expect(assigns[:file_set]).to eq file_set
            end
          end
        end

        describe "#edit" do
          let(:file_set) do
            create(:file_set, read_groups: ['public'])
          end

          let(:file) do
            Hydra::Derivatives::IoDecorator.new(File.open(fixture_path + '/world.png'),
                                                'image/png', 'world.png')
          end

          before do
            Hydra::Works::UploadFileToFileSet.call(file_set, file)
          end

          context "someone else's files" do
            it "sets flash error" do
              get :edit, params: { id: file_set }
              expect(response.code).to eq '401'
              expect(response).to render_template('unauthorized')
              expect(response).to render_template('dashboard')
            end
          end
        end

        describe "#show" do
          let(:file_set) do
            create(:file_set, title: ['test file'], user: user)
          end

          # TODO: can't get the bread crumbs to work out
          context "without a referer", skip: true do
            it "shows me the file and set breadcrumbs" do
              expect(controller).to receive(:add_breadcrumb).with('Home',
                                                                  Hyrax::Engine.routes.url_helpers.root_path(locale: 'en'))
              expect(controller).to receive(:add_breadcrumb).with( I18n.t('hyrax.dashboard.title'),
                                                                   Hyrax::Engine.routes.url_helpers.
                                                                     dashboard_path(locale: 'en') )
              get :show, params: { id: file_set }
              expect(response).to be_successful
              expect(flash).to be_empty
              expect(assigns[:presenter]).to be_kind_of Hyrax::FileSetPresenter
              expect(assigns[:presenter].id).to eq file_set.id
              expect(assigns[:presenter].events).to be_kind_of Array
              expect(assigns[:presenter].fixity_check_status).to eq 'Fixity checks have not yet been run on this object'
            end
          end

          context "with a referer" do
            let(:work) do
              create( :data_set_work,
                      :public,
                      creator: [ "Dr. Creator" ],
                      rights_license: "The Rights License",
                      title: ['test title'],
                      user: user )
            end

            before do
              request.env['HTTP_REFERER'] = 'http://test.host/foo'
              work.ordered_members << file_set
              work.save!
              file_set.save!
            end

            it "shows me the breadcrumbs" do
              expect(controller).to receive(:add_breadcrumb).with('Home',
                                                                  Hyrax::Engine.routes.url_helpers.root_path(locale: 'en'))
              expect(controller).to receive(:add_breadcrumb).with('Dashboard',
                                                                  Hyrax::Engine.routes.url_helpers.
                                                                    dashboard_path(locale: 'en'))
              expect(controller).to receive(:add_breadcrumb).with('Works',
                                                                  Hyrax::Engine.routes.url_helpers.
                                                                    my_works_path(locale: 'en'))
              expect(controller).to receive(:add_breadcrumb).with('test title',
                                                                  main_app.hyrax_data_set_path(work.id, locale: 'en'))
              expect(controller).to receive(:add_breadcrumb).with('test file',
                                                                  main_app.hyrax_file_set_path(file_set, locale: 'en'))
              get :show, params: { id: file_set }
              expect(response).to be_successful
            end
          end
        end

        context 'someone elses (public) files' do
          let(:creator) { create(:user, email: 'archivist1@example.com') }
          let(:public_file_set) { create(:file_set, user: creator, read_groups: ['public']) }

          before { sign_in user }

          describe '#edit' do
            it 'gives me the unauthorized page' do
              get :edit, params: { id: public_file_set }
              expect(response.code).to eq '401'
              expect(response).to render_template(:unauthorized)
              expect(response).to render_template('dashboard')
            end
          end

          describe '#show' do
            before { get :show, params: { id: public_file_set } }
            it_behaves_like 'it is successful'
          end

        end
      end
    end
    it_behaves_like 'shared when signed in', false
    it_behaves_like 'shared when signed in', true
  end

  describe 'anonymous_link' do
    RSpec.shared_examples 'shared anonymous_link' do |dbg_verbose|
      subject { described_class }
      before do
        described_class.file_sets_controller_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose
      end
      after do
        described_class.file_sets_controller_debug_verbose = debug_verbose
      end
      context do

        describe '#anonymous_link' do

          describe 'for private file', skip: false do
            let(:parent) do
              create( :data_set_work,
                      :public,
                      creator: [ "Dr. Creator" ],
                      rights_license: "The Rights License",
                      title: ['test title'],
                      user: user )
            end
            let(:file_set) do
              create(:file_set, user: user).tap do |file_set|
                parent.ordered_members << file_set
                parent.save!
              end
            end
            let :anon_link_obj do
              AnonymousLink.create itemId: file_set.id,
                                   path: Rails.application.routes.url_helpers.hyrax_file_set_path(id: file_set,
                                                                                                  locale: 'en')
            end
            let(:anon_link_id) { anon_link_obj.downloadKey }

            context 'allows access' do

              before do
                expect(::Deepblue::WorkViewContentService).to receive(:content_find_by_id).
                  with(id: file_set.id).and_return file_set
                expect(::Hyrax::AnonymousLinkService).to receive(:find_anonymous_link_obj).
                  with(link_id: anon_link_id).and_return anon_link_obj
                # expect(parent).to receive(:tombstone).and_call_original
                expect(::Hyrax::AnonymousLinkService).to_not receive(:anonymous_link_destroy_if_tombstoned)
                # expect(parent).to receive(:published?).and_call_original
                expect(::Hyrax::AnonymousLinkService).to_not receive(:anonymous_link_destroy_if_published)
                expect(controller).to receive(:additional_response_formats).with(ActionController::MimeResponds::Collector)
                get :anonymous_link, params: { id: file_set, anon_link_id: anon_link_id }
              end
              # expect(controller.anonymous_link?).to eq true
              # expect(response).to fail_redirect_and_flash(not_authorized)
              # it_behaves_like 'it is successful anonymous'
              it 'redirects' do
                # TODO: fix
                expect(response.status).to eq 302
              end
            end

          end

          describe 'for tombstoned parent', skip: false do
            let(:parent) do
              create( :data_set_work,
                      :public,
                      creator: [ "Dr. Creator" ],
                      rights_license: "The Rights License",
                      title: ['test title'],
                      tombstone: ['reason'],
                      user: user )
            end
            let(:file_set) do
              create(:file_set, user: user).tap do |file_set|
                parent.ordered_members << file_set
                parent.save!
              end
            end
            let :anon_link_obj do
              AnonymousLink.create itemId: file_set.id,
                                   path: Rails.application.routes.url_helpers.hyrax_file_set_path(id: file_set,
                                                                                                  locale: 'en')
            end
            let(:anon_link_id) { anon_link_obj.downloadKey }

            context 'allows access' do

              before do
                expect(::Deepblue::WorkViewContentService).to receive(:content_find_by_id).
                  with(id: file_set.id).and_return file_set
                expect(::Hyrax::AnonymousLinkService).to receive(:find_anonymous_link_obj).
                  with(link_id: anon_link_id).and_return anon_link_obj
                # expect(parent).to receive(:tombstone).and_call_original
                expect(::Hyrax::AnonymousLinkService).to receive(:anonymous_link_destroy_if_tombstoned).and_call_original
                # expect(parent).to_not receive(:published?).and_call_original
                expect(::Hyrax::AnonymousLinkService).to_not receive(:anonymous_link_destroy_if_published)
                expect(::Hyrax::AnonymousLinkService).to receive(:anonymous_link_destroy!).with( anon_link_obj )
                get :anonymous_link, params: { id: file_set, anon_link_id: anon_link_id }
              end
              it 'redirects' do
                expect(controller.anonymous_link?).to eq true
                expect(response).to_not be_nil
                expect(response.status).to eq 302
                # TODO: fix
                # expect(response).to redirect_to(main_app.hyrax_file_set_path( id: file_set.id ))
                # expect(flash[:alert]).to eq "flash_msg"
              end
            end

          end

          describe 'for public file' do
            let(:parent) do
              create( :data_set_work,
                      :public,
                      creator: [ "Dr. Creator" ],
                      rights_license: "The Rights License",
                      title: ['test title'],
                      user: user )
            end
            let(:file_set) do
              create(:file_set, user: user, read_groups: ['public']).tap do |file_set|
                parent.ordered_members << file_set
                parent.save!
              end
            end
            let :anon_link_obj do
              AnonymousLink.create itemId: file_set.id,
                                   path: Rails.application.routes.url_helpers.hyrax_file_set_path(id: file_set,
                                                                                                  locale: 'en')
            end
            let(:anon_link_id) { anon_link_obj.downloadKey }

            context 'allows access' do

              before do
                expect(::Deepblue::WorkViewContentService).to receive(:content_find_by_id).
                  with(id: file_set.id).and_return file_set
                expect(::Hyrax::AnonymousLinkService).to receive(:find_anonymous_link_obj).
                  with(link_id: anon_link_id).and_return anon_link_obj
                expect(controller).to receive(:additional_response_formats).with(ActionController::MimeResponds::Collector)
                get :anonymous_link, params: { id: file_set, anon_link_id: anon_link_id }
              end
              it_behaves_like 'it is successful anonymous'
            end
          end

        end

      end
    end
    it_behaves_like 'shared anonymous_link', false
    it_behaves_like 'shared anonymous_link', true
  end

  describe '#assign_to_work_as_read_me' do
    RSpec.shared_examples 'shared #assign_to_work_as_read_me' do |dbg_verbose|
      subject { described_class }
      before do
        described_class.file_sets_controller_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose
      end
      after do
        described_class.file_sets_controller_debug_verbose = debug_verbose
      end
      context '', skip: false do

        describe 'when not signed in' do
          let(:file_set)  { create(:file_set, read_groups: ['public']) }
          before { get :assign_to_work_as_read_me, params: { id: file_set.id } }
          it_behaves_like 'it requires login'
        end

        describe 'when not editor' do
          let(:parent) do
            create( :data_set_work,
                    :public,
                    creator: [ "Dr. Creator" ],
                    rights_license: "The Rights License",
                    title: ['test title'],
                    user: user )
          end
          let(:file_set) do
            create(:file_set, user: user).tap do |file_set|
              parent.ordered_members << file_set
              parent.save!
            end
          end

          before do
            sign_in user
            expect(parent).to_not receive(:read_me_update)
          end

          describe 'it fails because' do
            it 'unauthorized' do
              get :assign_to_work_as_read_me, params: { id: file_set.id }
              expect(response.status).to eq 302
              expect(flash[:alert]).to include(not_authorized)
            end
          end

        end

        describe 'when editor' do
          let(:parent) do
            create( :data_set_work,
                    :public,
                    creator: [ "Dr. Creator" ],
                    rights_license: "The Rights License",
                    title: ['test title'],
                    user: user )
          end
          let(:file_set) do
            create(:file_set, user: user).tap do |file_set|
              parent.ordered_members << file_set
              parent.save!
            end
          end

          before do
            sign_in user
            # expect(::Deepblue::WorkViewContentService).to receive(:content_find_by_id).
            #   with(id: file_set.id).and_return file_set
            allow(controller.current_ability).to receive(:can?).with(:edit, file_set).and_return(true)
            allow(controller.current_ability).to receive(:can?).with(:assign_to_work_as_read_me, file_set).and_return(true)
            expect(controller).to receive(:assign_to_work_as_read_me).and_call_original
            expect(controller).to receive(:assign_to_work_as_read_me_test)
          end

          describe 'it succeeds because' do
            it 'calls the parent and sets the read me' do
              get :assign_to_work_as_read_me, params: { id: file_set.id }
              # TODO: fix
              # expect(file_set).to have_received(:parent)
              # TODO: fix
              # expect(file_set.parent).to have_received(:read_me_update).with( file_set: file_set )
              # For some reason the redirect in the response from the controller does not match this:
              # expect(response).to redirect_to main_app.hyrax_data_set_path( id: parent.id, locale: 'en')
              expect(response.status).to eq 302
              expect(flash[:notice]).to include(I18n.t('hyrax.file_sets.notifications.assigned_as_read_me',
                                                       filename: file_set.label ))
            end
          end

        end

      end
    end
    it_behaves_like 'shared #assign_to_work_as_read_me', false
    it_behaves_like 'shared #assign_to_work_as_read_me', true
  end

  describe '#create_anonymous_link' do
    RSpec.shared_examples 'shared #create_anonymous_link' do |dbg_verbose|
      # subject { described_class }
      before do
        described_class.file_sets_controller_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose
      end
      after do
        described_class.file_sets_controller_debug_verbose = debug_verbose
      end
      context '', skip: false do

        context 'when not signed in' do
          let(:file_set)  { create(:file_set) }
          before do
            get :create_anonymous_link, params: { id: file_set.id }
          end
          it_behaves_like 'it requires login'
        end

        describe 'when editor' do
          let(:parent) do
            create( :data_set_work,
                    :public,
                    creator: [ "Dr. Creator" ],
                    rights_license: "The Rights License",
                    title: ['test title'],
                    user: user )
          end
          let(:file_set) do
            create(:file_set, user: user).tap do |file_set|
              parent.ordered_members << file_set
              parent.save!
            end
          end

          before do
            sign_in user
            allow(controller.current_ability).to receive(:can?).with(:edit, file_set).and_return(true)
            allow(controller.current_ability).to receive(:can?).with(:create_anonymous_link, file_set).and_return(true)
          end

          describe 'it succeeds for create show' do
            let(:commit) { I18n.t( 'simple_form.actions.anonymous_link.create_show' ) }
            before do
              expect(controller).to receive(:anonymous_link_find_or_create).with( id: file_set.id, link_type: 'show' )
            end
            it 'calls the parent and sets the read me' do
              get :create_anonymous_link, params: { id: file_set.id, commit: commit }
              expect(response).to redirect_to main_app.hyrax_file_set_path( id: file_set.id ) + '#anonymous_links'
              expect(response.status).to eq 302
              # TODO: fix
              # expect(flash[:notice]).to include(I18n.t('hyrax.file_sets.notifications.assigned_as_read_me',
              #                                  filename: file_set.label ))
            end
          end

        end

      end
    end
    it_behaves_like 'shared #create_anonymous_link', false
    it_behaves_like 'shared #create_anonymous_link', true
  end

  describe '#create_single_use_link' do
    RSpec.shared_examples 'shared #create_single_use_link' do |dbg_verbose|
      subject { described_class }
      before do
        described_class.file_sets_controller_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose
      end
      after do
        described_class.file_sets_controller_debug_verbose = debug_verbose
      end
      context '', skip: false do
        context 'when not signed in' do
          let(:file_set)  { create(:file_set) }
          before do
            get :create_single_use_link, params: { id: file_set.id }
          end
          it_behaves_like 'it requires login'
        end

      end
    end
    it_behaves_like 'shared #create_single_use_link', false
    it_behaves_like 'shared #create_single_use_link', true
  end

  describe '#display_provenance_log' do
    RSpec.shared_examples 'shared #display_provenance_log' do |dbg_verbose|
      subject { described_class }
      before do
        described_class.file_sets_controller_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose
      end
      after do
        described_class.file_sets_controller_debug_verbose = debug_verbose
      end
      context '', skip: false do

        before do
          expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug)
        end

        context 'when not signed in' do
          let(:file_set)  { create(:file_set) }
          before do
            get :display_provenance_log, params: { id: file_set.id }
          end
          it_behaves_like 'it requires login'
        end

        describe 'signed in' do
          let(:file_set) do
            create(:file_set, title: ['test file'], user: user)
          end

          before do
            sign_in user
            expect(::Deepblue::ProvenancePath).to receive(:path_for_reference).with(file_set.id).and_call_original
            expect(::Deepblue::ProvenanceLogService).to receive(:entries).with(file_set.id, refresh: true)
          end

          it 'redirects to show the provenance log tab' do
            get :display_provenance_log, params: { id: file_set.id }
            expect(response).to redirect_to main_app.hyrax_file_set_path( id: file_set.id ) + '#provenance_log_display'
            expect(response.status).to eq 302
          end
        end

      end
    end
    it_behaves_like 'shared #display_provenance_log', false
    it_behaves_like 'shared #display_provenance_log', true
  end

  describe '#doi' do
    RSpec.shared_examples 'shared #doi' do |dbg_verbose|
      subject { described_class }
      before do
        described_class.file_sets_controller_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose
      end
      after do
        described_class.file_sets_controller_debug_verbose = debug_verbose
      end
      context '', skip: false do

        context 'when not signed in' do
          let(:file_set)  { create(:file_set) }
          before do
            get :doi, params: { id: file_set.id }
          end
          it_behaves_like 'it requires login'
        end

        context 'when signed in' do
          let(:parent) do
            create( :data_set_work,
                    :public,
                    creator: [ "Dr. Creator" ],
                    rights_license: "The Rights License",
                    title: ['test title'],
                    user: user )
          end

          let(:expected_mint_msg) { "The expected mint message." }

          # see doi_controller_behavior.rb
          before do
            expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug)
            sign_in user
            create(:sipity_entity, proxy_for_global_id: parent.to_global_id.to_s)
          end

          context 'work with any doi state' do
            let(:file_set) do
              create(:file_set, user: user).tap do |file_set|
                parent.ordered_members << file_set
                parent.save!
              end
            end
            # let(:work) do
            #   w = create(:data_set_with_one_file, user: user, depositor: user.email, doi: nil)
            #   w.depositor = user.email
            #   w
            # end

            it 'redirects' do
              # expect(controller).to receive(:doi_mint)
              allow(ActiveFedora::Base).to receive(:find).with(file_set.id).and_return(file_set)
              expect(controller).to receive(:doi_mint).and_return expected_mint_msg
              # expect(work).to receive(:doi_mint).with( current_user: user, event_note: DataSet.class.name )
              get :doi, params: { id: file_set.id }
              expect(response.status).to eq 302
              expect(response).to redirect_to main_app.hyrax_file_set_path(file_set, locale: 'en')
              expect(flash[:notice]).to eq expected_mint_msg
            end

          end

          context 'private work pending doi', skip: true do
            let(:file_set) do
              create(:file_set, user: user, doi: ::Deepblue::DoiBehavior.doi_pending).tap do |file_set|
                parent.ordered_members << file_set
                parent.save!
              end
            end

            it 'redirects' do
              allow(ActiveFedora::Base).to receive(:find).with(file_set.id).and_return(file_set)
              expect(controller).to receive(:doi_mint).and_return expected_mint_msg
              # expect(work).to_not receive(:doi_mint).with( current_user: user, event_note: DataSet.class.name )
              get :doi, params: { id: work }
              expect(response).to redirect_to main_app.hyrax_data_set_path(work, locale: 'en')
            end

          end

        end

      end
    end
    it_behaves_like 'shared #doi', false
    it_behaves_like 'shared #doi', true
  end

  context '#file_contents', skip: true do

    before do
      expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug)
    end

  end

  context '#single_use_link', skip: true do

    before do
      expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug)
    end

  end

  # namespace :hyrax, path: :concern do
  #   resources :file_sets do
  #     member do
  #       get    'assign_to_work_as_read_me'
  #       post   'create_anonymous_link'
  #       post   'create_single_use_link'
  #       get    'display_provenance_log'
  #       get    'doi'
  #       post   'doi'
  #       get    'file_contents'
  #       get    'anonymous_link/:anon_link_id', action: :anonymous_link
  #       get    'single_use_link/:link_id', action: :single_use_link
  #     end
  #   end
  # end


end
