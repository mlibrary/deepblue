require 'rails_helper'

RSpec.describe 'hyrax/file_sets/media_display/_default.html.erb', type: :view do
  let(:file_set)      { stub_model(FileSet) }
  let(:config)        { double("config") }
  let(:link)          { true }
  let(:presenter)     { double("presenter") }
  let(:download_path) { "/some/unique/download/path" }

  before do
    allow(Hyrax.config).to receive(:display_media_download_link?).and_return(link)
    allow( presenter ).to receive( :can_download_file? ).and_return true
    allow( presenter ).to receive( :download_path_link ).and_return download_path
    allow( view ).to receive(:presenter).and_return( presenter )
    assign( :presenter, presenter )
    render 'hyrax/file_sets/media_display/default', file_set: file_set, presenter: presenter
  end

  it "draws the view with the link" do
    expect(rendered).to include download_path
    expect(rendered).to have_css('div.no-preview')
    expect(rendered).to have_css('a', text: 'Download the file')
  end

  it "includes google analytics data in the download link" do
    expect(rendered).to include download_path
    expect(rendered).to have_css('a#file_download')
    expect(rendered).to have_selector("a[data-label=\"#{file_set.id}\"]")
  end

  context "no download links" do
    let(:link) { false }

    it "draws the view without the link" do
      expect(rendered).not_to include download_path
      expect(rendered).to have_css('div.no-preview')
      expect(rendered).not_to have_css('a', text: 'Download the file')
    end
  end

end
