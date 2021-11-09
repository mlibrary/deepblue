# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Deepblue::DraftAdminSetService do

  describe 'resolve constants and module variables' do
    it { expect( ::Deepblue::DraftAdminSetService::NOT_AN_ADMIN_SET_ID ).to eq 'NOT_AN_ADMIN_SET_ID' }
    it { expect( ::Deepblue::DraftAdminSetService.draft_admin_set_service_debug_verbose ).to eq false }
    it { expect( ::Deepblue::DraftAdminSetService.draft_admin_set_title ).to eq 'Draft works Admin Set' }
    it { expect( ::Deepblue::DraftAdminSetService.draft_workflow_state_name ).to eq 'draft' }
  end

  describe '.is_draft_admin_set?' do
    let(:default_adminset) { build(:default_adminset) }
    let(:draft_adminset) { build(:draft_data_set_adminset) }
    it { expect( ::Deepblue::DraftAdminSetService.is_draft_admin_set? nil ).to eq false }
    it { expect( ::Deepblue::DraftAdminSetService.is_draft_admin_set? '' ).to eq false }
    it { expect( ::Deepblue::DraftAdminSetService.is_draft_admin_set? default_adminset ).to eq false }
    context 'with draft admin set' do
      before do
        allow(::Deepblue::DraftAdminSetService).to receive(:draft_admin_set_id).and_return draft_adminset.id
      end
      it { expect( ::Deepblue::DraftAdminSetService.is_draft_admin_set? draft_adminset ).to eq true }
    end
  end

end
