# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::Renderers::LinkedAttributeRenderer do
  let(:field) { :name }
  let(:renderer) { described_class.new(field, ['Bob', 'Jessica']) }

  describe "#attribute_to_html" do
    subject { Nokogiri::HTML(renderer.render) }

    let(:expected) { Nokogiri::HTML(tr_content) }

    let(:tr_content) do
      "<tr><th>Name</th>\n" \
       "<td><ul class='tabular'>" \
       "<li class=\"attribute attribute-name\"><a href=\"/catalog?locale=en&q=Bob&amp;search_field=name\">Bob</a></li>\n" \
       "<li class=\"attribute attribute-name\"><a href=\"/catalog?locale=en&q=Jessica&amp;search_field=name\">Jessica</a></li>\n" \
       "</ul></td></tr>"
    end

    it { expect(renderer).not_to be_microdata(field) }
    it { expect(subject).to be_equivalent_to(expected) }
  end
end
