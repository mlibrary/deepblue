# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::Renderers::AttributeRenderer, skip: false do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.attribute_renderer_debug_verbose ).to eq debug_verbose }
  end


  let(:field) { :name }
  let(:renderer) { described_class.new(field, ['Bob', 'Jessica']) }
  let(:yml_path) { File.join(fixture_path, 'config', 'schema_org.{yml}') }

  before do
    Hyrax::Microdata.load_paths += Dir[yml_path]
    Hyrax::Microdata.reload!
  end
  after do
    Hyrax::Microdata.load_paths -= Dir[yml_path]
    Hyrax::Microdata.reload!
  end

  describe "#attribute_to_html" do
    subject { Nokogiri::HTML(renderer.render) }

    let(:expected) { Nokogiri::HTML(tr_content) }

    context 'without microdata enabled' do
      before do
        allow(Hyrax.config).to receive(:display_microdata?).and_return(false)
      end
      let(:tr_content) do
        "<tr><th>Name</th>\n" \
         "<td><ul class='tabular'><li class=\"attribute attribute-name\">Bob</li>\n" \
         "<li class=\"attribute attribute-name\">Jessica</li>\n" \
         "</ul></td></tr>"
      end

      it { expect(renderer).not_to be_microdata(field) }
      it { expect(subject).to be_equivalent_to(expected) }
    end

    context 'with an integer attribute' do
      let(:field) { :height }
      let(:renderer) { described_class.new(field, [567]) }
      let(:tr_content) do
        "<tr><th>Height</th>\n" \
         "<td><ul class='tabular'><li class=\"attribute attribute-height\">567</li>\n" \
         "</ul></td></tr>"
      end

      it { expect(subject).to be_equivalent_to(expected) }
    end

    context 'with microdata enabled', skip: true do
      let(:tr_content) do
        "<tr><th>Name</th>\n" \
         "<td><ul class='tabular'><li class=\"attribute attribute-name\" itemscope itemtype=\"http://schema.org/Person\" itemprop=\"name\">" \
         "<span itemprop=\"firstName\">Bob</span></li>\n" \
         "<li class=\"attribute attribute-name\" itemscope itemtype=\"http://schema.org/Person\" itemprop=\"name\">" \
         "<span itemprop=\"firstName\">Jessica</span></li>\n" \
         "</ul></td></tr>"
      end

      it { expect(renderer).to be_microdata(field) }
      it { expect(subject).to be_equivalent_to(expected) }
    end

    context 'with links and < characters' do
      let(:field) { :description }
      let(:renderer) { described_class.new(field, ['Foo < Bar http://www.example.com. & More Text']) }
      let(:tr_content) do
        "<tr><th>Description</th>\n" \
         "<td><ul class='tabular'><li class=\"attribute attribute-description\">" \
         "<span itemprop=\"description\">Foo &lt; Bar " \
         "<a href=\"http://www.example.com\">http://www.example.com</a>. &amp; More Text</span></li>\n" \
         "</ul></td></tr>"
      end

      it { expect(subject).to be_equivalent_to(expected) }
    end
  end

  describe "#render_dl_row" do
    subject { Nokogiri::HTML(renderer.render_dl_row) }

    let(:expected) { Nokogiri::HTML(dl_content) }
    let(:dl_content) do
      "<dt>Name</dt>\n" \
       "<dd><ul class='tabular'><li class=\"attribute attribute-name\">Bob</li>\n" \
       "<li class=\"attribute attribute-name\">Jessica</li>\n" \
       "</ul></dd>"
    end

    before do
      allow(Hyrax.config).to receive(:display_microdata?).and_return(false)
    end

    it { expect(renderer).not_to be_microdata(field) }
    it { expect(subject).to be_equivalent_to(expected) }
  end

  describe "#label" do
    subject { renderer }
    context 'with label provided as an option' do
      let(:given_label) { "Peeps we know" }
      let(:renderer) { described_class.new(field, ['Bob', 'Jessica'], label: given_label) }

      it 'renders the provided label' do
        expect(subject.label).to eq(given_label)
      end
    end

    context 'with work type option' do
      let(:work_type) { "DataSet".underscore }
      let(:renderer) { described_class.new(field, ['Bob', 'Jessica'], work_type: work_type) }

      context 'no work type specific label' do
        it { expect(subject.label).to eq(field.to_s.humanize) }
      end
      context 'work type specific label' do
        let(:work_type_name_label) { "Name" }

        before do
          allow(I18n).to receive(:translate).and_call_original
          allow(I18n).to receive(:translate).with(:"blacklight.search.fields.#{work_type}.show.#{field}", {}) do
            work_type_name_label
          end
        end
        it { expect(subject.label).to eq(work_type_name_label) }
      end
    end
  end
end
