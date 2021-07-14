require 'rails_helper'

RSpec.describe 'hyrax/file_sets/_anonymous_links.html.erb', type: :view do
  let(:user)          { create(:user) }
  let(:solr_document) { SolrDocument.new(id: '1234', 'has_model_ssim' => 'FileSet') }
  let(:ability)       { Ability.new(user) }
  let(:presenter)     { Hyrax::DsFileSetPresenter.new(solr_document, ability) }

  context "with no anonymous links" do
    before do
      allow( view ).to receive( :presenter ).and_return( presenter )
      assign( :presenter, presenter )
      allow( presenter ).to receive( :anonymous_links ).and_return([])
      allow( presenter ).to receive( :can_download_file? ).and_return true
      render 'hyrax/file_sets/anonymous_links.html.erb', presenter: presenter
    end
    it "renders a table with no links" do
      expect(rendered).to include("<tr><td>#{I18n.t('hyrax.anonymous_links.table.no_links')}</td></tr>")
    end
  end

  context "with single use links" do
    let(:link)           { SingleUseLink.create(itemId: "1234", downloadKey: "sha2hashb") }
    let(:link_presenter) { Hyrax::SingleUseLinkPresenter.new(link) }

    before do
      controller.params = { id: "1234" }
      allow(view).to receive(:presenter).and_return(presenter)
      assign( :presenter, presenter )
      allow( presenter ).to receive( :anonymous_links ).and_return( [link_presenter] )
      allow( presenter ).to receive( :can_download_file? ).and_return true
      render 'hyrax/file_sets/anonymous_links.html.erb', presenter: presenter
    end
    it "renders a table with links" do
      expect( rendered ).to have_text I18n.t('hyrax.anonymous_links.expiration_message',
                                             link_type: "View",
                                             link: "sha2ha",
                                             time: "in 11 months, 4 weeks, 2 days, 4 hours, 39 minutes, and 53 seconds" )
    end

    it "renders note to add to next link" do
      expect( rendered ).to have_content I18n.t('simple_form.labels.anonymous_link.user_comment')
      # expect( rendered ).to have_content "Create Download Anonymous Link"
    end
  end

end
