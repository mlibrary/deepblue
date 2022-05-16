require 'rails_helper'

RSpec.describe 'hyrax/base/_form_files.html.erb', type: :view, skip: false do
  let(:model) { stub_model(DataSet) }
  let(:form) { Hyrax::DataSetForm.new(model, double, controller) }
  let(:f) { double(object: form) }

  before do
    stub_template 'hyrax/uploads/_js_templates.html.erb' => 'templates'
    # TODO: stub_model is not stubbing new_record? correctly on ActiveFedora models.
    allow(model).to receive(:new_record?).and_return(false)
  end

  context "without browse_everything" do
    before do
      allow(Hyrax.config).to receive(:browse_everything?).and_return(false)
      render 'hyrax/base/form_files', f: f
    end

    it 'shows a message and buttons' do
      expect(rendered).to have_content 'If you have more than 100 files or files larger than 5 GB please Contact Us'
      expect(rendered).to have_content('Add files...')
      # expect(rendered).not_to have_content('Add folder...')

      expect(rendered).not_to have_content 'cloud provider'
      expect(rendered).not_to have_selector('button#browse-btn')
    end
  end

  context "with browse_everything" do
    before do
      allow(Hyrax.config).to receive(:browse_everything?).and_return(true)
      render 'hyrax/base/form_files', f: f
    end

    it 'shows user timing warning' do
      expect(rendered).to have_content 'Note that if you use a cloud provider to upload a large number of'
      expect(rendered).to have_selector("button[id='browse-btn'][data-target='#edit_data_set_#{form.model.id}']")
    end
  end
end
