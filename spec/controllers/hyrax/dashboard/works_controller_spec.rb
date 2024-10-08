# frozen_string_literal: true
# Updated: hyrax4
require 'rails_helper'

RSpec.describe ::Hyrax::Dashboard::WorksController, type: :controller, skip: false do
  describe "#search_builder_class" do
    subject { controller.blacklight_config.search_builder_class }

    it { is_expected.to eq Hyrax::Dashboard::WorksSearchBuilder }
  end

  describe "#search_facet_path" do
    subject { controller.send(:search_facet_path, id: 'keyword_sim') }

    it { is_expected.to eq "/dashboard/works/facet/keyword_sim?locale=en" }
  end
end
