# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Hyrax::FilterSuppressed do

  describe 'constants' do
    it "resolves them" do
      expect( ::Hyrax::FilterSuppressed.filter_suppressed_debug_verbose ).to eq false
    end
  end

end
