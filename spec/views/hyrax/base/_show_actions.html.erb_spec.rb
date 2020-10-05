require 'rails_helper'

RSpec.describe 'hyrax/base/_show_actions.html.erb', type: :view do

  let(:presenter) { Hyrax::DataSetPresenter.new(solr_document, ability) }
  let(:solr_document) { SolrDocument.new(attributes) }
  let(:attributes) { { "has_model_ssim" => ["DataSet"], :id => "0r967372b" } }
  let(:ability) { double('ability') }
  let(:member) { Hyrax::DataSetPresenter.new(member_document, ability) }
  let(:member_document) { SolrDocument.new(member_attributes) }
  let(:member_attributes) { { "has_model_ssim" => ["DataSet"], :id => "8336h190k" } }
  let(:curation_concern) { create(:public_data_set, id: "8336h190k", title: ['public thing']) }
  # let(:data_set_controller) { double('data_set_controller') }
  let(:data_set_controller) { Hyrax::DataSetsController.new }

  before do
    allow(ability).to receive(:can?).with(:create, FeaturedWork).and_return(false)
    assign( :presenter, presenter )
    assign( :curation_concern, curation_concern )
    presenter.controller = data_set_controller
    # member.controller = controller
  end

  context "as an unregistered user" do
    before do
      allow(presenter).to receive(:show_deposit_for?).with(anything).and_return(false)
      allow(ability).to receive(:admin?).and_return false
      allow(presenter).to receive(:editor?).and_return false
      allow(presenter).to receive(:tombstone).and_return nil
      render 'hyrax/base/show_actions.html.erb', presenter: presenter, curation_concern: curation_concern
    end

    it "doesn't show edit / delete / Add to collection links" do
      expect(rendered).not_to have_button I18n.t('simple_form.actions.data_set.edit_work')
      expect(rendered).not_to have_button I18n.t('simple_form.actions.data_set.delete')
      # expect(rendered).not_to have_link 'Add to collection'
    end
  end

  context "as an editor" do
    before do
      allow(presenter).to receive(:show_deposit_for?).with(anything).and_return true
      allow(presenter).to receive(:editor?).and_return(true)
      allow(presenter).to receive(:tombstone).and_return nil
      allow(ability).to receive(:admin?).and_return false
      allow(ability).to receive(:can?).with(:edit, presenter.id).and_return true
    end

    context "when the work does not contain children" do
      before do
        allow(presenter).to receive(:member_presenters).and_return([])
        allow(ability).to receive(:admin?).and_return false
        render 'hyrax/base/show_actions.html.erb', presenter: presenter, curation_concern: curation_concern
      end

      it "does not show file manager link" do
        expect(rendered).not_to have_link I18n.t("hyrax.file_manager.link_text")
      end

      it "shows edit / delete links" do
        expect(rendered).to have_text I18n.t('simple_form.actions.data_set.edit_work')
        expect(rendered).to have_text I18n.t('simple_form.actions.data_set.delete')
        # expect(rendered).not_to have_button 'Add to collection'
      end
    end

    context "when the work contains 1 child" do
      before do
        allow(presenter).to receive(:member_presenters).and_return([member])
        render 'hyrax/base/show_actions.html.erb', presenter: presenter, curation_concern: curation_concern
      end
      it "has a zip download / globus link" do
        expect(rendered).to have_button I18n.t('simple_form.actions.data_set.zip_download')
        expect(rendered).to have_button I18n.t('simple_form.actions.data_set.globus_download')
      end
      it "does not show file manager link" do
        expect(rendered).not_to have_button I18n.t("hyrax.file_manager.link_text")
      end
    end

    # TODO: this test is broken for Deepblue Data
    # context "when the work contains 2 children" do
    #   let(:file_member) { Hyrax::FileSetPresenter.new(file_document, ability) }
    #   let(:file_document) { SolrDocument.new(file_attributes) }
    #   let(:file_attributes) { { id: '1234' } }
    #
    #   before do
    #     allow(presenter).to receive(:member_presenters).and_return([member, file_member])
    #     render 'hyrax/base/show_actions.html.erb', presenter: presenter, curation_concern: curation_concern
    #   end
    #   it "has a zip download link" do
    #     expect(rendered).to have_text I18n.t('simple_form.actions.data_set.zip_download')
    #     expect(rendered).to have_button I18n.t('simple_form.actions.data_set.zip_download')
    #     expect(rendered).to have_button I18n.t('simple_form.actions.data_set.globus_download')
    #   end
    #   it "shows file manager link" do
    #     expect(rendered).to have_text I18n.t("hyrax.file_manager.link_text")
    #   end
    # end

  end

end
