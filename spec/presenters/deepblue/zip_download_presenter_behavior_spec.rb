require 'rails_helper'

class TestPresenter 

   include Deepblue::ZipDownloadPresenterBehavior

   attr_accessor :show_actions_debug_verbose
   def show_actions_debug_verbose
     @show_actions_debug_verbose ||= false
   end
   attr_accessor :show_actions_bold_puts
   def show_actions_bold_puts
     @show_actions_bold_puts ||= false
   end

   def initialize 
   end

   def id
     'id'
   end

   def solr_document
   end

   def anonymous_show?
   end 

   def anonymous_use_show?
      	false
   end  

   def single_use_show?
   end 

   def single_use_link_download ( main_app:, curation_concern:)
   end   
   
end


RSpec.describe Deepblue::ZipDownloadPresenterBehavior do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.zip_download_presenter_behavior_debug_verbose ).to eq( debug_verbose )
    end
  end

  describe '#example', skip: false do
    RSpec.shared_examples 'shared #example' do |dbg_verbose|
      subject { described_class }
      before do
        described_class.zip_download_presenter_behavior_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose
      end
      after do
        described_class.zip_download_presenter_behavior_debug_verbose = debug_verbose
      end
      context do

        let(:solr_document) { SolrDocument.new(attributes) }
        let(:user_key) { 'a_user_key' }

        let(:attributes) do
          { "id" => '888888',
            "title_tesim" => ['foo', 'bar'],
            "human_readable_type_tesim" => ["Generic Work"],
            "has_model_ssim" => ["DataSet"],
            "date_created_tesim" => ['an unformatted date'],
            "depositor_tesim" => user_key }
        end

        let( :test_object ) { double('test_object') }
        let( :test_object2 ) { double('test_object2') }

        it "is TODO", skip: true do
          presenter = TestPresenter.new
          allow(presenter).to receive(:zip_download_presenter_behavior_debug_verbose).and_return false
          allow(presenter).to receive(:zip_download_enabled?).and_return true
          allow(presenter).to receive(:anonymous_show?).and_return true

          dc = presenter.can_download_zip_maybe?
          expect(dc).to eq(true)
        end

        it "checks if zipdownload is enabled" do
          presenter = TestPresenter.new
          allow(::Deepblue::ZipDownloadService).to receive(:zip_download_enabled).and_return true

          dc = presenter.zip_download_enabled?
          expect(dc).to eq(true)
          ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
        end

        it "is TODO", skip: true do
          presenter = TestPresenter.new
          allow(::Deepblue::ZipDownloadService).to receive(:zip_download_enabled).and_return true

          dc = presenter.zip_download_link( main_app: test_object, curation_concern: test_object2 )
          expect(dc).to eq(true)
        end

        it "determines zip download max total file size to download" do
          presenter = TestPresenter.new
          #allow(::Deepblue::ZipDownloadService).to receive(:zip_download_min_total_file_size_to_download_warn).and_return 10

          dc = presenter.zip_download_max_total_file_size_to_download
          expect(dc).to eq(10737418240)
          ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
        end

        it "warns of zip download min total file size to download" do
          presenter = TestPresenter.new

          dc = presenter.zip_download_min_total_file_size_to_download_warn
          expect(dc).to eq(1073741824)
          ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
        end

        it "determins if download total file size is too big" do
          presenter = TestPresenter.new
          allow(presenter).to receive(:zip_download_max_total_file_size_to_download).and_return 10
          allow(presenter).to receive(:solr_document).and_return test_object
          allow(test_object).to receive(:total_file_size).and_return 100

          dc = presenter.zip_download_total_file_size_too_big?
          expect(dc).to eq(true)
        end

        it "warns zip download total file size" do
          presenter = TestPresenter.new
          allow(presenter).to receive(:zip_download_min_total_file_size_to_download_warn).and_return 10
          allow(presenter).to receive(:solr_document).and_return test_object
          allow(test_object).to receive(:total_file_size).and_return 100

          dc = presenter.zip_download_total_file_size_warn?
          expect(dc).to eq(true)
        end

        it "determines zip download path link" do
          presenter = TestPresenter.new
          allow(presenter).to receive(:zip_download_min_total_file_size_to_download_warn).and_return 10
          allow(presenter).to receive(:solr_document).and_return test_object
          allow(test_object).to receive(:total_file_size).and_return 100
          allow(presenter).to receive(:anonymous_show?).and_return true
          allow(presenter).to receive(:single_use_show?).and_return true
          allow(presenter).to receive(:single_use_link_download).and_return test_object
          allow(test_object).to receive(:download_key).and_return "123"
          allow(test_object).to receive(:item_id).and_return 'item_id'
          allow(test_object).to receive(:path).and_return 'path'

          dc = presenter.zip_download_path_link(main_app: test_object, curation_concern: solr_document)
          expect(dc).to eq("/data/single_use_link/download/123")
        end

      end
    end
    it_behaves_like 'shared #example', false
    it_behaves_like 'shared #example', true
  end

end
