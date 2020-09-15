require 'rails_helper'

RSpec.describe 'hshared/show_curation_notes.html.erb' do
  let( :curation_notes_admin ) { ['Curation notes displayed for an admin'] }
  let( :curation_notes_user ) { ['Curation notes displayed for a user'] }

  let( :attributes_curation_notes_admin ) do
    {
        Solrizer.solr_name('has_model', :symbol) => ["DataSet"],
        curation_notes_admin_tesim: curation_notes_admin,
        curation_notes_user_tesim: []
    }
  end
  let( :attributes_curation_notes_both ) do
    {
        Solrizer.solr_name('has_model', :symbol) => ["DataSet"],
        curation_notes_admin_tesim: curation_notes_admin,
        curation_notes_user_tesim: curation_notes_user
    }
  end
  let( :attributes_curation_notes_user ) do
    {
      Solrizer.solr_name('has_model', :symbol) => ["DataSet"],
      curation_notes_admin_tesim: [],
      curation_notes_user_tesim: curation_notes_user
    }
  end
  let(:ability) { double(Ability) }
  let( :solr_document_admin_only ) { SolrDocument.new( attributes_curation_notes_admin ) }
  let( :solr_document_both ) { SolrDocument.new( attributes_curation_notes_both ) }
  let( :solr_document_user_only ) { SolrDocument.new( attributes_curation_notes_user ) }

  context 'with just user notes' do
    let( :presenter ) do
      Hyrax::WorkShowPresenter.new( solr_document_user_only, ability )
    end
    before do
      allow(view).to receive(:current_ability).and_return(ability)
      allow( ability ).to receive( :admin? ).and_return true
      assign( :presenter, presenter )
      # allow( presenter ).to receive( :curation_notes_admin ).and_return nil
      # allow( presenter ).to receive( :curation_notes_user ).and_return curation_notes_user
      # stub_template 'shared/show_curation_note.html.erb' => 'Stubbed Show Curation Note'
      render 'shared/show_curation_notes', { presenter: presenter,
                                             mode: 'table',
                                             i18n_label_admin: 'show.labels.curation_notes_admin',
                                             i18n_label_user: 'show.labels.curation_notes_user' }
    end

    it 'does what it did' do
      expect(rendered).to include 'Curation notes displayed for a user'
    end
  end

  context 'with just admin notes' do
    let( :presenter ) do
      Hyrax::WorkShowPresenter.new( solr_document_admin_only, ability )
    end

    it 'notes are visible when admin' do
      allow(view).to receive(:current_ability).and_return(ability)
      allow( ability ).to receive( :admin? ).and_return true
      assign( :presenter, presenter )
      # allow( presenter ).to receive( :curation_notes_admin ).and_return curation_notes_admin
      # allow( presenter ).to receive( :curation_notes_user ).and_return nil
      # stub_template 'shared/show_curation_note.html.erb' => 'Stubbed Show Curation Note'
      render 'shared/show_curation_notes', { presenter: presenter,
                                             mode: 'table',
                                             i18n_label_admin: 'show.labels.curation_notes_admin',
                                             i18n_label_user: 'show.labels.curation_notes_user' }
      expect(rendered).to include 'Curation notes displayed for an admin'
    end

    it 'notes are not visible when not admin' do
      allow(view).to receive(:current_ability).and_return(ability)
      allow( ability ).to receive( :admin? ).and_return false
      assign( :presenter, presenter )
      # allow( presenter ).to receive( :curation_notes_admin ).and_return curation_notes_admin
      # allow( presenter ).to receive( :curation_notes_user ).and_return nil
      # stub_template 'shared/show_curation_note.html.erb' => 'Stubbed Show Curation Note'
      render 'shared/show_curation_notes', { presenter: presenter,
                                             mode: 'table',
                                             i18n_label_admin: 'show.labels.curation_notes_admin',
                                             i18n_label_user: 'show.labels.curation_notes_user' }
      expect(rendered).not_to include 'Curation notes displayed for an admin'
    end
  end

end
