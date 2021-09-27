require 'rails_helper'

class TestPresenter 
   include Deepblue::DeepbluePresenterBehavior
end


RSpec.describe Deepblue::DeepbluePresenterBehavior do

  let(:dummy_class) { double }
  let(:dummy2_class) { double }
  
  before do
    allow(dummy_class).to receive(:action_mailer).and_return dummy2_class
    allow(dummy2_class).to receive(:default_url_options).and_return "options"

    allow(dummy2_class).to receive(:download_path_link).and_return "download_path_link"
    allow(dummy2_class).to receive(:thumbnail_post_process).and_return "thumb"     
    allow(dummy_class).to receive(:can_download_file?).and_return true    
  end


  xit "is TODO" do
  	presenter = TestPresenter.new
    dc = presenter.default_url_options

    allow(Rails.application).to receive(:config).and_return dummy_class

    expect(dc).to eq("collid1")
  end

  it "generates a download path link" do
    presenter = TestPresenter.new
    dc = presenter.download_path_link main_app: dummy_class, curation_concern: dummy2_class

    expect(dc).to eq("download_path_link")
  end

  it "presently does nothing" do
  	presenter = TestPresenter.new
    dc = presenter.member_thumbnail_image_options member: nil

    expect(dc).to eq({})
  end

  it "returns a thumbnail url option" do
  	presenter = TestPresenter.new
    dc = presenter.member_thumbnail_url_options dummy_class
    expect(dc).to eq({:suppress_link=>false})
  end

  it "generates a post post process" do
  	presenter = TestPresenter.new
    dc = presenter.member_thumbnail_post_process main_app: nil, member: dummy2_class, tag: "tag"
    expect(dc).to eq("thumb")
  end
end
