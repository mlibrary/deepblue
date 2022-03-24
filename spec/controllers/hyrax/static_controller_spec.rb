require 'rails_helper'

RSpec.describe Hyrax::StaticController, type: :controller do

  include Devise::Test::ControllerHelpers
  let(:main_app) { Rails.application.routes.url_helpers }
  let(:hyrax) { Hyrax::Engine.routes.url_helpers }

  let(:debug_verbose) { false }

  describe 'module debug verbose variables', skip: false do
    it { expect( described_class.static_controller_debug_verbose ).to eq( debug_verbose ) }
    it { expect( ::Deepblue::StaticContentControllerBehavior.static_content_controller_behavior_verbose ).to eq( debug_verbose ) }
    it { expect( ::Deepblue::StaticContentControllerBehavior.static_content_cache_debug_verbose ).to eq( false ) }
  end

  describe '::Deepblue::WorkViewContentService constants', skip: false do
    it { expect(::Deepblue::WorkViewContentService.documentation_collection_title ).to eq "DBDDocumentationCollection" }
    it { expect(::Deepblue::WorkViewContentService.documentation_work_title_prefix ).to eq "DBDDoc-" }
    it { expect(::Deepblue::WorkViewContentService.documentation_email_title_prefix ).to eq "DBDEmail-" }
    it { expect(::Deepblue::WorkViewContentService.documentation_i18n_title_prefix ).to eq "DBDI18n-" }
    it { expect(::Deepblue::WorkViewContentService.documentation_view_title_prefix ).to eq "DBDView-" }
    it { expect(::Deepblue::WorkViewContentService.export_documentation_path ).to eq '/tmp/documentation_export' }

    it { expect(::Deepblue::WorkViewContentService.static_content_controller_behavior_menu_verbose ).to eq false }
    it { expect(::Deepblue::WorkViewContentService.static_content_enable_cache ).to eq true }
    it { expect(::Deepblue::WorkViewContentService.static_content_interpolation_pattern ).to eq /(?-mix:%%)|(?-mix:%\{([\w|]+)\})|(?-mix:%<(\w+)>(.*?\d*\.?\d*[bBdiouxXeEfgGcps]))/ }
    it { expect(::Deepblue::WorkViewContentService.static_controller_redirect_to_work_view_content ).to eq false }
  end

  def create_documentation_collection( dbddocs: [] )
    # puts "#{__LINE__} create_documentation_collection"
    id = 0
    doc_col = create(:collection_lw,
                     id: 'dbddoc',
                     title: [::Deepblue::WorkViewContentService.documentation_collection_title],
                     with_permission_template: true,
                     with_solr_document: true )
    id += 1
    work = create_doc_col_work(doc_col, id: id, title: 'DBDDocumentation')
    id += 1
    create_doc_col_fs(work, id: id, title: 'dbd_menu.yml', mime_type: 'text/x-yaml')
    dbddocs.each do |doc|
      description = ['menu: DBDDocumentation/dbd_menu.yml']
      id += 1
      work = create_doc_col_work(doc_col, id: id, title: "DBDDoc-#{doc}")
      id += 1
      create_doc_col_fs(work, id: id, title: "#{doc}.html", mime_type: 'text/html', description: description )
    end
    # Array(doc_col.ordered_members).each do |work|
    #   puts "work=#{work}"
    # end
    return doc_col
  end

  def create_doc_col_work( doc_col, id:, title: )
    # puts "#{__LINE__} create_doc_col_work id=#{id} title=#{title}"
    create(:data_set, id: id, title: [title] ).tap do |work|
      doc_col.ordered_members << work
      doc_col.save
    end
  end

  def create_doc_col_fs( parent, id:, title:, label: nil, mime_type:, description: [] )
    # puts "#{__LINE__} create_doc_col_fs id=#{id} title=#{title}"
    label = title unless label
    path = File.join fixture_path, 'work_view', title
    # content: File.open(path)
    fs = create(:file_set_with_files,
                id: id,
                title: [title],
                label: label,
                description: description,
                file_path: path )

    # puts "create_doc_col_fs fs=#{fs} fs.files[0]=#{fs.files[0]} fs.files[0].original_name=#{fs.files[0].original_name}"
    parent.ordered_members << fs
    parent.save!
    return fs
  end

  describe '#show', :clean_repo do
    routes { Rails.application.routes }
    before do
      # create_documentation_collection
    end

    RSpec.shared_examples 'shared show static page' do |doc|
      describe 'doc' do
        let(:work_title) { "DBDDoc-#{doc}" }
        let(:file_name)  { "#{doc}.html" }
        let(:path)       { "/#{work_title}/#{file_name}" }
        before do
          create_documentation_collection
          ::Deepblue::StaticContentControllerBehavior.static_content_cache_reset
          expect(controller).to receive(:static_content_find_documentation_file_set).with( work_title: work_title,
                                                                                         file_name: file_name,
                                                                                         path: path ).and_call_original
        end
        after do
          ::Deepblue::StaticContentControllerBehavior.static_content_cache_reset
        end
        context 'when not logged in' do
          it 'shows page' do
            get :show, params: { doc: doc }
            expect(response.code).to eq '200'
            expect(response).to render_template "layouts/homepage"
            # expect(response).to render_template "hyrax/static/#{file_name}"
          end
        end
        context 'when logged in' do
          before { sign_in user }
          it 'shows page' do
            get :show, params: { doc: doc }
            expect(response.code).to eq '200'
            expect(response).to render_template "layouts/homepage"
            # expect(response).to render_template "hyrax/static/#{file_name}"
          end
        end
      end
    end

    RSpec.shared_examples 'shared show work-view page' do |doc, doc_text|
      # puts "#{__LINE__} doc=#{doc}"
      describe 'doc' do
        let(:path) { "/DBDDoc-#{doc}/#{doc}.html" }
        before do
          create_documentation_collection( dbddocs: [doc] )
          ::Deepblue::StaticContentControllerBehavior.static_content_cache_reset
          expect(controller).to receive(:static_content_find_documentation_file_set).with( work_title: "DBDDoc-#{doc}",
                                                                           file_name: "#{doc}.html",
                                                                           path: path ).and_call_original
        end
        after do
          ::Deepblue::StaticContentControllerBehavior.static_content_cache_reset
        end
        context 'when not logged in' do
          it 'shows page' do
            get :show, params: { doc: doc }
            expect(response.code).to eq '302'
            expect(response).to redirect_to "#{::DeepBlueDocs::Application.config.relative_url_root}/work_view_content#{path}"
            # get :show, params: { doc: doc }
            # expect(response.code).to eq '200'
            # expect(response.body).to include doc_text
            # expect(response.body).to include path
          end
        end
        # context 'when logged in' do
        #   before { sign_in user }
        #   it 'shows page 200' do
        #     get :show, params: { doc: doc }
        #     expect(response.code).to eq '302'
        #     expect(response).to redirect_to "#{::DeepBlueDocs::Application.config.relative_url_root}/work_view_content#{path}"
        #     get :show, params: { doc: doc }
        #     expect(response.code).to eq '200'
        #     expect(response.body).to include doc_text
        #     # expect(response).to render_template "layouts/homepage"
        #     # expect(response).to render_template "hyrax/static/#{dbddoc_doc_file_name}"
        #   end
        # end
      end
    end

    RSpec.shared_examples 'shared #show' do |dbg_verbose|
      # puts "#{__LINE__} dbg_verbose=#{dbg_verbose}"
      subject { described_class }

      before do
        described_class.static_controller_debug_verbose = dbg_verbose
        # ::Deepblue::StaticContentControllerBehavior.static_content_controller_behavior_verbose = dbg_verbose
        # ::Deepblue::LoggingHelper.echo_to_puts = true if dbg_verbose
        # expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once).and_call_original if dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose
      end
      after do
        # ::Deepblue::LoggingHelper.echo_to_puts = false if dbg_verbose
        # ::Deepblue::StaticContentControllerBehavior.static_content_controller_behavior_verbose = debug_verbose
        described_class.static_controller_debug_verbose = debug_verbose
      end
      context do
        let(:user) { create(:user) }

        describe 'about' do
          it_behaves_like 'shared show static page', 'about'
          it_behaves_like 'shared show work-view page', 'about', 'About Deep Blue Data'
        end

        describe 'about-top', skip: false do
          it_behaves_like 'shared show static page', 'about' # it gets turned into about
        end

        describe 'agreement', skip: false do
          it_behaves_like 'shared show static page', 'agreement'
        end

        describe 'depositor-guide', skip: false do
          it_behaves_like 'shared show static page', 'depositor-guide'
        end

        describe 'faq', skip: false do
          it_behaves_like 'shared show static page', 'faq'
        end

        describe 'help', skip: false do
          it_behaves_like 'shared show static page', 'faq' # it gets turned into faq
        end

        describe 'globus-help', skip: false do
          let(:doc)        { 'globus-help' }
          let(:target_url) {"#{::DeepBlueDocs::Application.config.relative_url_root}/user-guide#download-globus"}
          context 'when not logged in' do
            it 'shows page' do
              get :show, params: { doc: doc }
              expect(response).to redirect_to target_url
            end
          end
          context 'when logged in' do
            before { sign_in user }
            it 'shows page' do
              get :show, params: { doc: doc }
              expect(response).to redirect_to target_url
            end
          end
        end

        describe 'rest-api', skip: false do
          it_behaves_like 'shared show static page', 'rest-api'
        end

        describe 'services', skip: false do
          it_behaves_like 'shared show static page', 'services'
        end

        describe 'user-guide', skip: false do
          it_behaves_like 'shared show static page', 'user-guide'
        end

        describe 'unknown_page', skip: false do
          let(:doc) { 'unknown_page' }
          context 'when not logged in' do
            it 'does not understand' do
              expect { get :show, params: { doc: doc } }.to raise_error(ActionController::UrlGenerationError,
                                                                        /No route matches/)
              ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
            end
          end
          context 'when logged in' do
            before { sign_in user }
            it 'does not understand' do
              expect { get :show, params: { doc: doc } }.to raise_error(ActionController::UrlGenerationError,
                                                                        /No route matches/)
              ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
            end
          end
        end

      end

    end
    #it_behaves_like 'shared #show', false
    it_behaves_like 'shared #show', true
  end

  describe '#mendeley', skip: false do
    routes { Hyrax::Engine.routes }
    RSpec.shared_examples 'shared #mendeley' do |dbg_verbose|
      subject { described_class }
      before do
        described_class.static_controller_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose
      end
      after do
        described_class.static_controller_debug_verbose = debug_verbose
      end
      context do
        it "renders page" do
          get "mendeley"
          expect(response).to be_success
          expect(response).to render_template "layouts/homepage"
          ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
        end
        it "renders no layout with javascript" do
          get :mendeley, xhr: true
          expect(response).to be_success
          expect(response).not_to render_template "layouts/homepage"
          ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
        end
      end
    end
    it_behaves_like 'shared #mendeley', false
    it_behaves_like 'shared #mendeley', true
  end

  describe '#zotero', skip: false do
    routes { Hyrax::Engine.routes }
    RSpec.shared_examples 'shared #zotero' do |dbg_verbose|
      subject { described_class }
      before do
        described_class.static_controller_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose
      end
      after do
        described_class.static_controller_debug_verbose = debug_verbose
      end
      context do
        it "renders page" do
          get "zotero"
          expect(response).to be_success
          expect(response).to render_template "layouts/homepage"
          ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
        end
        it "renders no layout with javascript" do
          get :zotero, xhr: true
          expect(response).to be_success
          expect(response).not_to render_template "layouts/homepage"
          ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
        end
      end
    end
    it_behaves_like 'shared #zotero', false
    it_behaves_like 'shared #zotero', true
  end

end
