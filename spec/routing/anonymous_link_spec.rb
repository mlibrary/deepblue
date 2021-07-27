require 'rails_helper'

RSpec.describe 'Routes for anonymous links', type: :routing, skip: false do

  # routes { Hyrax::Engine.routes }
  routes { Rails.application.routes }

  describe 'Single Use Link Viewer', skip: false do
    it 'routes to #show' do
      expect(show_anonymous_link_path('abc123')).to eq '/anonymous_link/show/abc123'
      expect(get("/anonymous_link/show/abc123")).to route_to("hyrax/anonymous_links_viewer#show", id: 'abc123')
    end

    it 'routes to #download' do
      expect(download_anonymous_link_path('abc123')).to eq '/anonymous_link/download/abc123'
      expect(post("/anonymous_link/download/abc123")).to route_to("hyrax/anonymous_links_viewer#download", id: 'abc123')
    end
  end

  describe 'Single Use Link Generator', skip: false do
    it 'routes to #create_show' do
      expect(generate_show_anonymous_link_path('abc123')).to eq '/anonymous_link/generate_show/abc123'
      expect(post("/anonymous_link/generate_show/abc123")).to route_to("hyrax/anonymous_links#create_anonymous_show", id: 'abc123')
    end

    it 'routes to #create_download' do
      expect(generate_download_anonymous_link_path('abc123')).to eq '/anonymous_link/generate_download/abc123'
      expect(post("/anonymous_link/generate_download/abc123")).to route_to("hyrax/anonymous_links#create_anonymous_download", id: 'abc123')
    end
  end

end
