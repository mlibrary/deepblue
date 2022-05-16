# frozen_string_literal: true
require 'rails_helper'
# require 'hyrax/doi/spec/shared_specs'
require 'shared_specs/datacite_doi_presenter_behavior.rb'
require 'shared_specs/doi_presenter_behavior.rb'

describe 'Hyrax::Doi::DataCiteDoiPresenterBehavior', skip: true do
  let(:presenter_class) do
    Class.new(Hyrax::DataSetPresenter) do
      include Hyrax::Doi::DoiPresenterBehavior
      include Hyrax::Doi::DataCiteDoiPresenterBehavior
    end
  end
  let(:solr_document_class) do
    Class.new(SolrDocument) do
      include Hyrax::Doi::SolrDocument::DoiBehavior
      include Hyrax::Doi::SolrDocument::DataCiteDoiBehavior
    end
  end

  it_behaves_like 'a DOI-enabled presenter'
  it_behaves_like 'a DataCite DOI-enabled presenter'
end
