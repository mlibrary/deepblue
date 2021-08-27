# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Deepblue::DraftAdminSetService do

  describe 'constants' do
    it "resolves them" do
      expect( ::Deepblue::DraftAdminSetService.draft_admin_set_service_debug_verbose ).to eq false

      expect( ::Deepblue::DraftAdminSetService.draft_admin_set_title ).to eq 'Draft works Admin Set'
      expect( ::Deepblue::DraftAdminSetService.draft_workflow_state_name ).to eq 'draft'
    end
  end

end
