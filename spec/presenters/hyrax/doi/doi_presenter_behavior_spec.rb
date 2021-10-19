# frozen_string_literal: true
require 'rails_helper'
# require 'hyrax/doi/spec/shared_specs'
require 'shared_specs/doi_presenter_behavior.rb'

describe 'Hyrax::Doi::DoiPresenterBehavior', skip: true do
  let(:presenter_class) do
    Class.new(Hyrax::GenericWorkPresenter) do
      include Hyrax::Doi::DoiPresenterBehavior
    end
  end
  let(:solr_document_class) do
    Class.new(SolrDocument) do
      include Hyrax::Doi::SolrDocument::DoiBehavior
    end
  end

  it_behaves_like 'a DOI-enabled presenter'
end
