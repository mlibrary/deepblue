require 'rails_helper'

RSpec.describe 'hyrax/file_sets/_versioning.html.erb', type: :view do
  let(:file_set) { stub_model(FileSet) }
  let(:user)          { factory_bot_create_user(:user) }
  let(:solr_document) { SolrDocument.new(id: '1234', 'has_model_ssim' => 'FileSet') }
  let(:ability)       { Ability.new(user) }
  let(:presenter)     { Hyrax::DsFileSetPresenter.new(solr_document, ability) }

  before do
    allow( view ).to receive( :presenter ).and_return( presenter )
    assign( :presenter, presenter )
    assign( :curation_concern, file_set )
    @curation_concern = file_set
    assign( :version_list, [] )
    stub_template "hyrax/uploads/_js_templates_versioning" => ""
    render 'hyrax/file_sets/versioning', file_set: file_set, curation_concern: file_set
  end

  context "without additional users" do
    it "draws the new version form without error" do
      expect( rendered ).to have_content "Upload New Version"
      expect( rendered ).to have_content "Choose New Version File"
      expect( rendered ).to have_content "Restore Previous Version"
      expect( rendered ).to have_content "Save Revision"
      # expect(rendered).to have_css("input[name='file_set[files][]']")
    end
  end

end
