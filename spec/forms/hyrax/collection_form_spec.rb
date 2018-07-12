# frozen_string_literal: true

require 'rails_helper'

describe Hyrax::Forms::CollectionForm do

  describe "#terms" do
    subject { described_class.terms }

    it { is_expected.to eq %i[
      authoremail
      based_near
      collection_type_gid
      contributor
      creator
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
