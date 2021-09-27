require 'rails_helper'

class TestPresenter 

   include Deepblue::ZipDownloadPresenterBehavior

   def initialize 
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


  xit "is TODO" do  	
  	presenter = TestPresenter.new 
  	allow(presenter).to receive(:can_download_zip_maybe?).and_return true
  	allow(presenter).to receive(:can_download_zip_confirm?).and_return true

    dc = presenter.can_download_zip? 
    expect(dc).to eq(true)
  end


  xit "is TODO" do  	
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
  end


  xit "is TODO" do  	
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
  end

  it "warns of zip download min total file size to download" do  	
  	presenter = TestPresenter.new 

    dc = presenter.zip_download_min_total_file_size_to_download_warn 
    expect(dc).to eq(1073741824)
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
  	allow(test_object).to receive(:downloadKey).and_return "123"

    dc = presenter.zip_download_path_link(main_app: test_object, curation_concern: solr_document)
    expect(dc).to eq("/data/single_use_link/download/123")
  end

end
