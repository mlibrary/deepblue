# frozen_string_literal: true
require 'rails_helper'
require 'shared_specs/doi_form_behavior.rb'

describe 'Hyrax::Doi::DoiFormBehavior', skip: true do
  let(:model_class) do
    Class.new(GenericWork) do
      include ::Deepblue::DoiBehavior
    end
  end
  let(:work) { model_class.new(title: ['Moomin']) }
  let(:form_class) do
    Class.new(Hyrax::GenericWorkForm) do
      include Hyrax::Doi::DoiFormBehavior
    end
  end
  let(:form) { form_class.new(work, nil, nil) }

  it_behaves_like 'a DOI-enabled form'
end
