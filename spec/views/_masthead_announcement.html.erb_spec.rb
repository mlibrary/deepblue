require 'rails_helper'

RSpec.describe '/_masthead_announcement.html.erb', type: :view, skip: false do

  let( :section_class ) { '<section class="update-alert--warning container-fluid">' }

  before do
    allow(Flipflop).to receive(:display_masthead_banner?).and_return true
  end

  context 'no banner flipflops set' do
    before do
      allow(Flipflop).to receive(:display_masthead_banner_standard?).and_return false
      allow(Flipflop).to receive(:display_masthead_banner_maintenance?).and_return false
      allow(Flipflop).to receive(:display_masthead_banner_outage?).and_return false
    end

    it 'renders no banner sections' do
      render
      expect(rendered.scan(section_class).size).to eq 0
      expect(rendered).not_to include t( "hyrax.masthead_banner.standard_html" )
      expect(rendered).not_to include t( "hyrax.masthead_banner.maintenance_html" )
      expect(rendered).not_to include t( "hyrax.masthead_banner.outage_banner_html" )
    end

  end

  context 'standard banner flipflop set' do
    before do
      allow(Flipflop).to receive(:display_masthead_banner_standard?).and_return true
      allow(Flipflop).to receive(:display_masthead_banner_maintenance?).and_return false
      allow(Flipflop).to receive(:display_masthead_banner_outage?).and_return false
    end

    it 'renders the banner section' do
      render
      expect(rendered.scan(section_class).size).to eq 1
      expect(rendered).to include t( "hyrax.masthead_banner.standard_html" )
      expect(rendered).not_to include t( "hyrax.masthead_banner.maintenance_html" )
      expect(rendered).not_to include t( "hyrax.masthead_banner.outage_banner_html" )
    end

  end

  context 'maintenance banner flipflop set' do
    before do
      allow(Flipflop).to receive(:display_masthead_banner_standard?).and_return false
      allow(Flipflop).to receive(:display_masthead_banner_maintenance?).and_return true
      allow(Flipflop).to receive(:display_masthead_banner_outage?).and_return false
    end

    it 'renders the banner section' do
      render
      expect(rendered.scan(section_class).size).to eq 1
      expect(rendered).not_to include t( "hyrax.masthead_banner.standard_html" )
      expect(rendered).to include t( "hyrax.masthead_banner.maintenance_html" )
      expect(rendered).not_to include t( "hyrax.masthead_banner.outage_banner_html" )
    end

  end

  context 'outage banner flipflop set' do
    before do
      allow(Flipflop).to receive(:display_masthead_banner_standard?).and_return false
      allow(Flipflop).to receive(:display_masthead_banner_maintenance?).and_return false
      allow(Flipflop).to receive(:display_masthead_banner_outage?).and_return true
    end

    it 'renders the banner section' do
      render
      expect(rendered.scan(section_class).size).to eq 1
      expect(rendered).not_to include t( "hyrax.masthead_banner.standard_html" )
      expect(rendered).not_to include t( "hyrax.masthead_banner.maintenance_html" )
      expect(rendered).to include t( "hyrax.masthead_banner.outage_banner_html" )
    end

  end

  context 'all banners flipflop set' do
    before do
      allow(Flipflop).to receive(:display_masthead_banner_standard?).and_return true
      allow(Flipflop).to receive(:display_masthead_banner_maintenance?).and_return true
      allow(Flipflop).to receive(:display_masthead_banner_outage?).and_return true
    end

    it 'renders the banner section' do
      render
      expect(rendered.scan(section_class).size).to eq 3
      expect(rendered).to include t( "hyrax.masthead_banner.standard_html" )
      expect(rendered).to include t( "hyrax.masthead_banner.maintenance_html" )
      expect(rendered).to include t( "hyrax.masthead_banner.outage_banner_html" )
    end

  end

end
