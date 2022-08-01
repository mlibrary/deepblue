# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::Renderers::FundedbyOtherAttributeRenderer do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.fundedby_other_attribute_renderer_debug_verbose ).to eq debug_verbose }
  end

  let(:field) { :fundedby_other }
  let(:one_fundedby_other) { ['Star Academy'] }
  let(:two_fundedby_other) { ['Star Academy', 'Uplift Institute'] }
  let(:label) {'Funded By Other Label'}
  let(:options) { {label: label} }

  describe '#attribute_value_index_to_html' do

    context 'one fundedby other' do
      let(:renderer) { described_class.new(field, one_fundedby_other, options) }
      let(:markup)   { [] }
      let(:expected) { [%(<span itemprop="#{field}" class="more">Star Academy</span>), "</li>"] }

      it { expect(renderer.attribute_value_index_to_html(markup,
                                                         one_fundedby_other.first,
                                                         0,
                                                         one_fundedby_other.size)).to eq expected }
      it 'renders' do
        renderer.attribute_value_index_to_html(markup, one_fundedby_other.first, 0, one_fundedby_other.size)
        expect(markup).to eq expected
      end
    end

    context 'two fundedby other first' do
      let(:renderer) { described_class.new(field, two_fundedby_other, options) }
      let(:markup)   { [] }
      let(:expected) { [%(<span itemprop="#{field}" class="more">Star Academy</span>), "</li>"] }

      it 'renders' do
        renderer.attribute_value_index_to_html(markup, two_fundedby_other.first, 0, one_fundedby_other.size)
        expect(markup).to eq expected
      end
    end

    context 'two fundedby other second' do
      let(:renderer) { described_class.new(field, two_fundedby_other, options) }
      let(:markup)   { [] }
      let(:expected) { [%(<span itemprop="#{field}" class="more">Uplift Institute</span>), "</li>"] }

      it 'renders' do
        renderer.attribute_value_index_to_html(markup, two_fundedby_other[1], 1, one_fundedby_other.size)
        expect(markup).to eq expected
      end
    end

  end

  describe '#render' do

    context 'one fundedby other' do
      let(:renderer) { described_class.new(field, one_fundedby_other, options) }
      let(:expected) { [
        %(<tr><th>#{label}</th>),
        %(<td><ul class='tabular_list'>),
        %(<li class="attribute attribute-#{field}">),
        %(<span itemprop="#{field}" class="more">Star Academy</span>),
        %(</li>),
        '',
        %(</ul></td></tr>) ].join("\n") }

      it { expect(renderer.render).to eq expected }
    end

    context 'two fundedby other' do
      let(:renderer) { described_class.new(field, two_fundedby_other, options) }
      let(:expected) { [
        %(<tr><th>#{label}</th>),
        %(<td><ul class='tabular_list'>),
        %(<li class="attribute attribute-#{field}">),
        %(<span itemprop="#{field}" class="more">Star Academy</span>),
        %(<p></p>),
        %(</li>),
        %(<li class="attribute attribute-#{field}">),
        %(<span itemprop="#{field}" class="more">Uplift Institute</span>),
        %(</li>),
        '',
        %(</ul></td></tr>) ].join("\n") }

      it { expect(renderer.render).to eq expected }
    end

  end

end
