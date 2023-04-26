# frozen_string_literal: true
# hyrax-orcid

RSpec.describe OrcidWork, type: :model do
  it { is_expected.to validate_presence_of(:work_uuid) }
  it { is_expected.to validate_presence_of(:put_code) }
  it { is_expected.to belong_to(:orcid_identity) }
end
