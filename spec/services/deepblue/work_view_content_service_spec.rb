# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Deepblue::WorkViewContentService do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.work_view_content_service_debug_verbose ).to eq debug_verbose }
  end

  let(:documentation_collection_title) { "DBDDocumentationCollection" }

  before do
    described_class.static_content_documentation_collection_id = nil
  end

  describe 'module debug verbose variables' do
    it { expect( described_class.interpolation_helper_debug_verbose ).to eq false }
    it { expect( described_class.static_content_controller_behavior_verbose ).to eq( false ) }
    it { expect( described_class.static_content_cache_debug_verbose ).to eq( false ) }
    it { expect( described_class.work_view_documentation_controller_debug_verbose ).to eq( false ) }
    it { expect( described_class.work_view_content_service_debug_verbose ).to eq( debug_verbose ) }
    it { expect( described_class.work_view_content_service_email_templates_debug_verbose ).to eq( false ) }
    it { expect( described_class.work_view_content_service_i18n_templates_debug_verbose ).to eq( false ) }
    it { expect( described_class.work_view_content_service_view_templates_debug_verbose ).to eq( false ) }
  end

  describe 'other module values' do
    it "resolves them" do
      expect( described_class.documentation_collection_title ).to eq documentation_collection_title
      expect( described_class.documentation_work_title_prefix ).to eq "DBDDoc-"
      expect( described_class.documentation_email_title_prefix ).to eq "DBDEmail-"
      expect( described_class.documentation_i18n_title_prefix ).to eq "DBDI18n-"
      expect( described_class.documentation_view_title_prefix ).to eq "DBDView-"
      expect( described_class.export_documentation_path ).to eq '/tmp/documentation_export'

      expect( described_class.static_content_controller_behavior_menu_verbose ).to eq false
      expect( described_class.static_content_enable_cache ).to eq true
      expect( described_class.static_content_interpolation_pattern ).to eq /(?-mix:%%)|(?-mix:%\{([\w|]+)\})|(?-mix:%<(\w+)>(.*?\d*\.?\d*[bBdiouxXeEfgGcps]))/
      expect( described_class.static_controller_redirect_to_work_view_content ).to eq false
    end
  end

  describe 'document collection exists', skip: false do
    RSpec.shared_examples 'shared document collection exists' do |dbg_verbose|
      subject { described_class }
      before do
        described_class.work_view_content_service_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose
      end
      after do
        described_class.work_view_content_service_debug_verbose = debug_verbose
      end
      context do
        let(:doc_col_id) { 'IDdbdoc' }
        let(:doc_col) { create(:collection_lw,
                               id: doc_col_id,
                               title: [documentation_collection_title],
                               with_permission_template: true,
                               with_solr_document: true ) }

        let(:dbd_work_view_id) { 'dbdwork' }
        let(:dbd_view_id) { 'dbdview' }
        let(:dbd_view_title) { "#{described_class.documentation_view_title_prefix}test" }
        let(:dbd_view_file1) do
          create(:file_set,
                 id: "#{dbd_view_id}1",
                 title: ["#{dbd_view_title}.file1"],
                 label: "#{dbd_view_title}.file1.txt" )
        end
        let(:dbd_view) do
          create(:data_set, id: dbd_work_view_id, title: [dbd_view_title] ).tap do |work|
            work.ordered_members << dbd_view_file1
            work.save!
            doc_col.ordered_members << work
            doc_col.save
          end
        end
        let(:solr_query) { "+generic_type_sim:Collection AND +title_tesim:#{documentation_collection_title}" }

        before do
          expect(solr_query).to eq "+generic_type_sim:Collection AND +title_tesim:DBDDocumentationCollection"
          allow(::Hyrax::SolrService).to receive(:query).with( solr_query, rows: 10 ).and_return [doc_col]
          allow(::Hyrax::SolrService).to receive(:query).with( "(member_of_collection_ids_ssim:#{doc_col_id})",
                                                                      rows: 1000,
                                                                      sort: ["system_create_dtsi asc"] ).and_call_original
        end

        describe ".content_documentation_collection_id" do
          before do
            expect(described_class.static_content_documentation_collection_id).to eq nil
            expect(described_class).to receive(:content_documentation_collection_id_init).and_call_original
          end

          it 'finds and returns the correct id' do
            expect(described_class.content_documentation_collection_id).to eq doc_col_id
          end

        end

        describe ".content_documentation_collection" do

          it 'finds and returns the document collection' do
            expect(described_class.content_documentation_collection).to eq doc_col
          end

        end

        describe ".content_find_by_id" do

          it 'finds and returns the object' do
            expect(described_class.content_find_by_id( id: dbd_view_file1.id ) ).to eq dbd_view_file1
            ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
          end

        end
      end
    end
    it_behaves_like 'shared document collection exists', false
    it_behaves_like 'shared document collection exists', true
  end

end
