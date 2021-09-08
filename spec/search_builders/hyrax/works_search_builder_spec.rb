# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Hyrax::WorksSearchBuilder do

  describe 'constants' do
    it "resolves them" do
      expect( ::Hyrax::WorksSearchBuilder.hyrax_search_builder_debug_verbose ).to eq false
    end
  end

end
