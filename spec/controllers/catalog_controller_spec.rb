# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CatalogController, type: :controller do

  include Devise::Test::ControllerHelpers
  routes { Rails.application.class.routes }
  let(:main_app) { Rails.application.routes.url_helpers }
  let(:hyrax) { Hyrax::Engine.routes.url_helpers }

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.catalog_controller_debug_verbose ).to eq debug_verbose
    end
  end

  describe 'module variables' do
    it "they have the right values" do
      expect(described_class.catalog_controller_allow_search_fix_for_json).to eq true
    end
  end

  it { expect(described_class.modified_field).to eq 'system_modified_dtsi' }
  it { expect(described_class.uploaded_field).to eq 'system_create_dtsi' }

  describe 'blacklight_config' do
    subject(:blacklight_config) { described_class.blacklight_config }

    it 'search_builder_class' do
      # expect(blacklight_config.search_builder_class).to be ::SearchBuilder
      expect(blacklight_config.search_builder_class).to be ::Hyrax::CatalogSearchBuilder
    end

    describe 'default_solr_params', skip: Rails.configuration.hyrax4_spec_skip do
      subject(:default_solr_params) { blacklight_config.default_solr_params }

      # Fields to query
      it 'qf' do
        expected_tesim_fields = %w[title
                                   creator
                                   creator_full_name
                                   creator_display
                                   subject
                                   description
                                   keyword
                                   contributor
                                   caption
                                   methodology
                                   name
                                   referenced_by
                                   transcript
                                   translation
                                   alt_text
                                   identifier
                                   table_of_contents]
        expected_fields = expected_tesim_fields.map { |field| described_class.solr_name(field, :stored_searchable) }
        # couple of non-tesim stragglers here
        expected_fields.push('grantnumber_tesim', 'isbn_numeric', 'identifier_ssim', 'doi_ssim', 'doi_url_ssim')
        # puts ["", "default_solr_params=#{default_solr_params.pretty_inspect}", ""].join("\n")
        expect(default_solr_params[:qf].split(' ')).to match_array(expected_fields)
      end

      # Select handler
      it 'qt' do
        expect(default_solr_params[:qt]).to eq('search')
      end

      # Rows per page
      it 'rows' do
        expect(default_solr_params[:rows]).to eq 10
      end
    end
  end

  describe 'controller' do
    it '#show_site_search?' do
      expect(controller.show_site_search?).to equal true
    end

    it 'render_bookmarks_control?' do
      expect(controller.render_bookmarks_control?).to equal false
    end
  end

  describe 'all', clean: true, skip: false do
    RSpec.shared_examples 'shared CatalogController' do |dbg_verbose|
      subject { described_class }
      before do
        described_class.catalog_controller_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose
      end
      after do
        described_class.catalog_controller_debug_verbose = debug_verbose
      end
      context do

        let(:user) { factory_bot_create_user(:user) }

        before do
          sign_in user
        end

        describe "#index" do
          let(:rocks) do
            DataSet.new(id: 'rock123', title: ['Rock Documents'], read_groups: ['public'])
          end

          let(:clouds) do
            DataSet.new(id: 'cloud123', title: ['Cloud Documents'], read_groups: ['public'],
                        keyword: ['frodo'])
          end

          before do
            objects.each { |obj| Hyrax::SolrService.add(obj.to_solr) }
            Hyrax::SolrService.commit
          end

          context 'with a non-work file' do
            let(:file) { FileSet.new(id: 'file123') }
            let(:objects) { [file, rocks, clouds] }

            it 'finds works, not files' do
              get :index
              expect(response).to be_successful
              expect(response).to render_template('catalog/index')

              ids = assigns(:response).documents.map(&:id)
              expect(ids).to include rocks.id
              expect(ids).to include clouds.id
              expect(ids).not_to include file.id
            end
          end

          context 'with collections' do
            let(:collection) { create(:public_collection_lw, keyword: ['rocks']) }
            let(:objects) { [collection, rocks, clouds] }

            it 'finds collections' do
              get :index, params: { q: 'rocks' }, xhr: true
              expect(response).to be_successful
              doc_list = assigns(:response).documents
              expect(doc_list.map(&:id)).to match_array [collection.id, rocks.id]
            end
          end

          describe 'term search', :clean_repo do
            let(:objects) { [rocks, clouds] }

            it 'finds works with the given search term' do
              get :index, params: { q: 'rocks', owner: 'all' }
              expect(response).to be_successful
              expect(response).to render_template('catalog/index')
              expect(assigns(:response).documents.map(&:id)).to contain_exactly(rocks.id)
            end
          end

          describe 'facet search' do
            let(:objects) { [rocks, clouds] }

            before do
              get :index, params: { 'f' => { 'keyword_tesim' => ['frodo'] } }
            end

            it 'finds faceted works', skip: Rails.configuration.hyrax4_spec_skip do
              expect(response).to be_successful
              expect(response).to render_template('catalog/index')
              expect(assigns(:response).documents.map(&:id)).to contain_exactly(clouds.id)
            end
          end

          describe 'full-text search', skip: 'Will DataSets have a full_text search?' do
            let(:objects) { [rocks, clouds] }

            it 'finds matching records' do
              get :index, params: { q: 'full_textfull_text' }
              expect(response).to be_successful
              expect(response).to render_template('catalog/index')
              expect(assigns(:response).documents.map(&:id)).to contain_exactly(clouds.id)
            end
          end

          context 'works by file metadata' do
            let(:objects) do
              [double(to_solr: file1), double(to_solr: file2),
               double(to_solr: work1), double(to_solr: work2)]
            end

            let(:work1) do
              { has_model_ssim: ["DataSet"], id: "ff365c76z", title_tesim: ["me too"],
                file_set_ids_ssim: ["ff365c78h", "ff365c79s"],
                read_access_group_ssim: ["public"], edit_access_person_ssim: ["user1@example.com"] }
            end

            let(:work2) do
              { has_model_ssim: ["DataSet"], id: "ff365c777", title_tesim: ["find me"],
                file_set_ids_ssim: [],
                read_access_group_ssim: ["public"], edit_access_person_ssim: ["user2@example.com"] }
            end

            let(:file1) do
              { has_model_ssim: ["FileSet"], id: "ff365c78h", title_tesim: ["find me"],
                file_set_ids_ssim: [],
                edit_access_person_ssim: [user.user_key] }
            end

            let(:file2) do
              { has_model_ssim: ["FileSet"], id: "ff365c79s", title_tesim: ["other file"],
                file_set_ids_ssim: [],
                edit_access_person_ssim: [user.user_key] }
            end

            it "finds a work and a work that contains a file set with a matching title" do
              get :index, params: { q: 'find me', search_field: 'all_fields' }
              expect(assigns(:response).documents.map(&:id)).to contain_exactly(work1[:id], work2[:id])
            end

            it "finds a work that contains a file set with a matching title" do
              get :index, params: { q: 'other file', search_field: 'all_fields' }
              # puts [ "", ::Deepblue::LoggingHelper.here, "assigns(:response)['response']['docs']=#{assigns(:response)['response']['docs'].pretty_inspect}", ""].join("\n")
              # puts [ "", ::Deepblue::LoggingHelper.here, "assigns(:response)['response']['docs'].map{ |hash| hash['id']=#{assigns(:response)['response']['docs'].map{ |hash| hash['id'] }.pretty_inspect}", ""].join("\n")
              expect(assigns(:response)['response']['docs'].map{ |hash| hash['id'] }).to contain_exactly(work1[:id])
            end

            it "finds a work with a matching title" do
              get :index, params: { q: 'me too', search_field: 'all_fields' }
              # expect(assigns(:response).map(&:id)).to contain_exactly(work1[:id])
              expect(assigns(:response).documents.map(&:id)).to contain_exactly(work1[:id])
            end

          end
        end
      end
    end
    it_behaves_like 'shared CatalogController', false
    ################it_behaves_like 'shared CatalogController', true
  end

end
