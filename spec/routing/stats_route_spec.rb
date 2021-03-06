require 'rails_helper'

RSpec.describe "stats routes", type: :routing do
  routes { Hyrax::Engine.routes }

  context "for works" do
    it 'routes to the controller' do
      expect(get: '/works/7/stats').to route_to(controller: 'hyrax/stats', action: 'work', id: '7')
    end
    it 'builds a url' do
      expect(url_for(controller: 'hyrax/stats', action: 'work', id: '7', only_path: true)).to eql('/works/7/stats')
    end
  end

  context "for files" do
    it 'routes to the controller' do
      expect(get: '/files/7/stats').to route_to(controller: 'hyrax/stats', action: 'file', id: '7')
    end
    it 'builds a url' do
      expect(url_for(controller: 'hyrax/stats', action: 'file', id: '7', only_path: true)).to eql('/files/7/stats')
    end
  end
end
