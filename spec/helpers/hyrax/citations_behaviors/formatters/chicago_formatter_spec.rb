require 'rails_helper'

RSpec.describe Hyrax::CitationsBehaviors::Formatters::ChicagoFormatter, skip: false do
  subject(:formatter) { described_class.new(:no_context) }

  let(:presenter) { Hyrax::WorkShowPresenter.new(SolrDocument.new(work.to_solr), :no_ability) }
  let(:work)      { build(:data_set, title: ['<ScrIPt>prompt("Confirm Password")</sCRIpt>']) }

  it 'sanitizes input' do
    expect(formatter.format(presenter).downcase).not_to include '<ScrIPt>prompt'.downcase
  end
end
