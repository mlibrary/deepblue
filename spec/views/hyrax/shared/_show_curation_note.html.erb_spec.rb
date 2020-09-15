require 'rails_helper'

RSpec.describe 'shared/show_curation_note.html.erb' do
  let( :curation_notes ) { ['This is the first curation note.', 'This is the second curation note.'] }

  before do
    render 'shared/show_curation_note', { curation_notes: curation_notes,
                                                  itemprop: "curation_notes_admin",
                                                  tag_class: "attribute attribute-curation-notes-admin",
                                                  tag: 'span'}
  end

  it 'displays all the curation notes' do
    expect(rendered).to include curation_notes[0]
    expect(rendered).to include curation_notes[1]
  end

  it 'TODO: shortens long curation notes' do
    # TODO:
  end

end
