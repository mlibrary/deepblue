# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Deepblue::WorkViewContentService do

  #before(:all) do

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.interpolation_helper_debug_verbose ).to eq false
      expect( described_class.static_content_controller_behavior_verbose ).to eq( false )
      expect( described_class.static_content_cache_debug_verbose ).to eq( false )
      expect( described_class.work_view_documentation_controller_debug_verbose ).to eq( false )
      expect( described_class.work_view_content_service_debug_verbose ).to eq( false )
      expect( described_class.work_view_content_service_email_templates_debug_verbose ).to eq( false )
      expect( described_class.work_view_content_service_i18n_templates_debug_verbose ).to eq( false )
      expect( described_class.work_view_content_service_view_templates_debug_verbose ).to eq( false )
    end
  end

  describe 'other module values' do
    it "resolves them" do
      expect( described_class.documentation_collection_title ).to eq "DBDDocumentationCollection"
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

  context "document collection exists" do
    let(:doc_col_id) { 'dbdoc' }
    let(:doc_col_title) { described_class.documentation_collection_title }
    let(:solr_query) { "+generic_type_sim:Collection AND +title_tesim:#{doc_col_title}" }
    let(:doc_col) { build(:collection_lw, id: doc_col_id, title: [doc_col_title], with_permission_template: true, with_solr_document: true ) }

    let(:dbd_view_id) { 'dbdview' }
    let(:dbd_view_title) { "#{described_class.documentation_view_title_prefix}test" }
    let(:dbd_view_file1) do
      create(:file_set,
             id: "#{dbd_view_id}1",
             title: ["#{dbd_view_title}.file1"],
             label: "#{dbd_view_title}.file1.txt" )
    end
    let(:dbd_view) do
      create(:data_set, id: dbdview, title: [dbd_view_title] )
      dbd_view.ordered_members << dbd_view_file1
      dbd_view.save!
    end

    before do
      expect(solr_query).to eq "+generic_type_sim:Collection AND +title_tesim:DBDDocumentationCollection"
      allow(::ActiveFedora::SolrService).to receive(:query).with( solr_query, rows: 10 ).and_return [doc_col]
      allow(::ActiveFedora::SolrService).to receive(:query).with( "(member_of_collection_ids_ssim:dbdoc)",
                                                                  rows: 1000,
                                                                  sort: ["system_create_dtsi asc"] ).and_call_original
    end

    describe ".content_documentation_collection_id" do

      it 'finds and returns the correct id' do
        expect(described_class.content_documentation_collection_id).to eq doc_col_id
      end

    end

    # describe ".content_documentation_collection" do
    #
    #   it 'finds and returns the document collection' do
    #     expect(described_class.content_documentation_collection).to eq doc_col
    #   end
    #
    # end

    describe ".content_find_by_id" do

      it 'finds and returns the object' do
        expect(described_class.content_find_by_id( id: dbd_view_file1.id ) ).to eq dbd_view_file1
      end

    end

  end

end
