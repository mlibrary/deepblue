# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::PermissionsController, skip: false do

  include Devise::Test::ControllerHelpers
  routes { Hyrax::Engine.routes }
  let(:main_app) { Rails.application.routes.url_helpers }

  let(:user) { factory_bot_create_user(:user) }
  let(:ability) { Ability.new(user) }

  before do
    sign_in user
    allow(ActiveFedora::Base).to receive(:find).with(work.id).and_return(work)
  end

  # Need to figure out how to give permissions here
  describe '#confirm', skip: true do
    let(:work) { build(:data_set, user: user, id: 'abc') }

    before do
      # https://github.com/samvera/active_fedora/issues/1251
      allow(work).to receive(:persisted?).and_return(true)
      expect(ability).to receive(:can?).with(:edit, work).and_return(true)
      expect(controller).to receive(:copy).and_call_original
    end

    it 'draws the page' do
      get :confirm, params: { id: work }
      expect(response).to be_successful
    end
  end

  describe '#copy' do
    let(:work) { create(:data_set, user: user) }

    it 'adds a worker to the queue' do
      expect(VisibilityCopyJob).to receive(:perform_later).with(work)
      post :copy, params: { id: work }
      expect(response).to redirect_to main_app.hyrax_data_set_path(work, locale: 'en')
      expect(flash[:notice]).to eq "Updating file permissions. This may take a few minutes. You may want to refresh your browser or return to this record later to see the updated file permissions.\n"
    end
  end

  describe '#confirm_access' do
    let(:work) { create(:data_set_with_one_file, user: user) }

    it 'draws the page' do
      get :confirm_access, params: { id: work }
      expect(response).to be_successful
    end
  end

  describe '#copy_access' do
    let(:work) { create(:data_set_with_one_file, user: user) }

    it 'adds a worker to the queue' do
      expect(VisibilityCopyJob).to receive(:perform_later).with(work)
      expect(InheritPermissionsJob).to receive(:perform_later).with(work)
      post :copy_access, params: { id: work }
      expect(response).to redirect_to main_app.hyrax_data_set_path(work, locale: 'en')
      expect(flash[:notice]).to eq 'Updating file access levels. This may take a few minutes. ' \
                                   'You may want to refresh your browser or return to this record ' \
                                   'later to see the updated file access levels.'
    end
  end
end
