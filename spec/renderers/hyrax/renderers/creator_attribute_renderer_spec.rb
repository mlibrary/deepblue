# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::Renderers::CreatorAttributeRenderer do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.creator_attribute_renderer_debug_verbose ).to eq debug_verbose }
  end

  let(:field) { :creator }
  let(:one_creator) { ['Savage, Clarke'] }
  let(:six_creators) { ['Savage, Clarke',
                        'Brookes, Ham',
                        'Littlejohn, Johnny',
                        'Mayfair, Monk',
                        'Renwick, Renny',
                        'Roberts, Long Tom'] }

  describe '#attribute_value_to_html' do
    let(:renderer) { described_class.new(field, one_creator) }
    let(:expected) { %(<span itemprop=\"name\"><a href=\"/catalog?f%5Bcreator_sim%5D%5B%5D=Savage%2C+Clarke&amp;locale=en\">Savage, Clarke</a></span>) }

    it { expect(renderer.attribute_value_to_html(one_creator.first)).to eq expected }
  end

  describe '#authors_compact' do
    let(:renderer) { described_class.new(field, one_creator) }
    let(:expected) { [
        %(<span itemprop="creator" class="moreauthor">),
        %( and <a href="/catalog?f%5Bcreator_sim%5D%5B%5D=Savage%2C+Clarke&amp;locale=en">Savage, Clarke</a>),
        %(</span>) ].join("\n") }

    it { expect(renderer.creators_compact).to eq expected }
  end

  describe '#render' do

    context 'less than six' do
      let(:renderer) { described_class.new(field, one_creator) }
      let(:expected) { [
        %(<tr><th>Creator</th>),
        %(<td><ul class='tabular'>),
        %(<li itemprop="creator" class="attribute attribute-creator"><span itemprop="name"><a href="/catalog?f%5Bcreator_sim%5D%5B%5D=Savage%2C+Clarke&amp;locale=en">Savage, Clarke</a></span></span></li>),
        %(</ul></td></tr>) ].join("\n") }


      it { expect(renderer.render).to eq expected }
    end

    context 'more than five' do
      let(:renderer) { described_class.new(field, six_creators) }
      let(:expected) { [
        %(<tr><th>Creator</th>),
        %(<td><ul class='tabular'>),
        %(<li itemprop="creator" class="attribute attribute-creator"><span itemprop="creator" class="moreauthor">),
        %(<a href="/catalog?f%5Bcreator_sim%5D%5B%5D=Savage%2C+Clarke&amp;locale=en">Savage, Clarke</a>; ),
        %(<a href="/catalog?f%5Bcreator_sim%5D%5B%5D=Brookes%2C+Ham&amp;locale=en">Brookes, Ham</a>; ),
        %(<a href="/catalog?f%5Bcreator_sim%5D%5B%5D=Littlejohn%2C+Johnny&amp;locale=en">Littlejohn, Johnny</a>; ),
        %(<a href="/catalog?f%5Bcreator_sim%5D%5B%5D=Mayfair%2C+Monk&amp;locale=en">Mayfair, Monk</a>; ),
        %(<a href="/catalog?f%5Bcreator_sim%5D%5B%5D=Renwick%2C+Renny&amp;locale=en">Renwick, Renny</a>; ),
        %( and <a href="/catalog?f%5Bcreator_sim%5D%5B%5D=Roberts%2C+Long+Tom&amp;locale=en">Roberts, Long Tom</a>),
        %(</span></li>),
        %(</ul></td></tr>) ].join("\n") }

      it { expect(renderer.render).to eq expected }
    end

  end

end
