# frozen_string_literal: true
require 'rails_helper'
require 'shared_specs/doi_form_behavior.rb'
require 'shared_specs/datacite_doi_form_behavior.rb'

describe 'Hyrax::Doi::DataCiteDoiFormBehavior', skip: true do
  let(:model_class) do
    Class.new(DataSet) do
      include ::Deepblue::DoiBehavior
      include Hyrax::Doi::DataCiteDoiBehavior
    end
  end
  let(:work) { model_class.new(title: ['Moomin']) }
  let(:form_class) do
    Class.new(Hyrax::DataSetForm) do
      include Hyrax::Doi::DoiFormBehavior
      include Hyrax::Doi::DataCiteDoiFormBehavior
    end
  end
  let(:form) { form_class.new(work, nil, nil) }

  it_behaves_like 'a DOI-enabled form'
  it_behaves_like 'a DataCite DOI-enabled form'
end
