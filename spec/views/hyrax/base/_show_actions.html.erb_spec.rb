# frozen_string_literal: true

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
    # puts "::Deepblue::GlobusIntegrationService.globus_download_dir=#{::Deepblue::GlobusIntegrationService.globus_download_dir}"
    # puts "Dir.exist?( ::Deepblue::GlobusIntegrationService.globus_download_dir )=#{Dir.exist?( ::Deepblue::GlobusIntegrationService.globus_download_dir )}"
    # puts "::Deepblue::GlobusIntegrationService.globus_prep_dir=#{::Deepblue::GlobusIntegrationService.globus_prep_dir}"
    # puts "Dir.exist?( ::Deepblue::GlobusIntegrationService.globus_prep_dir )=#{Dir.exist?( ::Deepblue::GlobusIntegrationService.globus_prep_dir )}"
    # puts "Dir.exist?( ::Deepblue::GlobusIntegrationService.globus_download_dir ) && Dir.exist?( ::Deepblue::GlobusIntegrationService.globus_prep_dir )=#{Dir.exist?( ::Deepblue::GlobusIntegrationService.globus_download_dir ) && Dir.exist?( ::Deepblue::GlobusIntegrationService.globus_prep_dir )}"
    # puts "::Deepblue::GlobusIntegrationService.globus_enabled=#{::Deepblue::GlobusIntegrationService.globus_enabled}"
    allow(presenter).to receive(:globus_enabled?).and_return true # why are we forced to do this here?
    allow(presenter).to receive(:analytics_subscribed?).and_return false
    allow(presenter).to receive(:globus_files_prepping?).and_return false
    allow(view).to receive(:current_user).and_return true
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


    describe 'analytics subscribe and unsubscribe buttons', skip: true do
      # let( :flipflop ) { class_double( "Flipflop" ) }

      before do
        allow( presenter ).to receive( :member_presenters     ).and_return []
        allow( presenter ).to receive( :analytics_subscribed? ).and_return false
        allow( presenter ).to receive( :can_edit_work?        ).and_return true
        allow( ability   ).to receive( :admin?                ).and_return true
      end

      context "no buttons when Flipflop.enable_local_analytics_ui? is false" do
        before do
          allow( AnalyticsHelper ).to receive( :enable_local_analytics_ui? ).and_return false
          render 'hyrax/base/show_actions.html.erb', presenter: presenter, curation_concern: curation_concern
        end
        it "not to have a subscribe button" do
          expect(rendered).not_to have_text t('simple_form.actions.data_set.analytics_subscribe')
        end
      end

      context "buttons when Flipflop.enable_local_analytics_ui? is true" do
        before do
          allow( AnalyticsHelper ).to receive( :enable_local_analytics_ui? ).and_return true
          allow( AnalyticsHelper ).to receive( :analytics_reports_admins_can_subscribe? ).and_return true
          render 'hyrax/base/show_actions.html.erb', presenter: presenter, curation_concern: curation_concern
        end
        it "have a subscribe button" do
          expect(rendered).to have_text t('simple_form.actions.data_set.analytics_subscribe')
        end
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
