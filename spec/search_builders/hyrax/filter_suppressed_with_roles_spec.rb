# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Hyrax::FilterSuppressedWithRoles do

  describe 'constants' do
    it "resolves them" do
      expect( ::Hyrax::FilterSuppressedWithRoles.hyrax_filter_suppressed_with_roles_debug_verbose ).to eq false
    end
  end

end
