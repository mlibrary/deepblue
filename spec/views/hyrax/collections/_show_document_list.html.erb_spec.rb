# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'hyrax/collections/_show_document_list.html.erb', type: :view, skip: false do
  let(:documents) { ["Hello", "World"] }

  before do
    stub_template('hyrax/collections/_show_document_list_row.html.erb' => "<%= document %>")
  end
  context 'when not logged in' do
    it "renders the documents without an Action section" do
      allow(view).to receive(:current_user).and_return(nil)
      render('hyrax/collections/show_document_list.html.erb', documents: documents)
      expect(rendered).to have_css('tbody', text: documents.join)
      expect(rendered).not_to have_css('th', text: 'Action')
    end
  end

  context 'when logged in' do
    it "renders the documents without an Action section" do
      allow(view).to receive(:current_user).and_return(true)
      render('hyrax/collections/show_document_list.html.erb', documents: documents)
      expect(rendered).to have_css('tbody', text: documents.join)
      expect(rendered).not_to have_css('th', text: 'Action')
    end
  end
end
