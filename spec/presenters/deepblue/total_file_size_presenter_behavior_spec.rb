require 'rails_helper'

class TestPresenter 

   include Deepblue::TotalFileSizePresenterBehavior

   def initialize
     @solr_document = { "test" => "ready" }
   end

   def human_readable(name)
     name
   end

end


RSpec.describe Deepblue::TotalFileSizePresenterBehavior do

  before do
  	allow(Solrizer).to receive(:solr_name).and_return "test"	
  end

  it "returns total file count" do
  	presenter = TestPresenter.new
    dc = presenter.total_file_count 

    expect(dc).to eq(5)
  end

  it "returns file size" do
  	presenter = TestPresenter.new
    dc = presenter.total_file_size 

    expect(dc).to eq("ready")
  end

  it "retuns total file size in human readable format" do
  	presenter = TestPresenter.new
    dc = presenter.total_file_size_human_readable

    expect(dc).to eq("ready")
  end

end
