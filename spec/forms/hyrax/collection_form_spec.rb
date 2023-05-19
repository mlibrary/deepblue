# frozen_string_literal: true

require 'rails_helper'

describe Hyrax::Forms::CollectionForm do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect(described_class.collection_form_debug_verbose).to eq debug_verbose }
  end

  describe "#terms" do
    subject { described_class.terms }

    it { is_expected.to eq %i[
      alternative_title
      authoremail
      based_near
      collection_type_gid
      contributor
      creator
      curation_notes_admin
      curation_notes_user
      date_coverage
      date_created
      description
      fundedby
      grantnumber
      identifier
      keyword
      language
      license
      methodology
      publisher
      referenced_by
      related_url
      representative_id
      resource_type
      rights_license
      subject
      subject_discipline
      thumbnail_id
      title
      visibility
    ] }
  end

end
