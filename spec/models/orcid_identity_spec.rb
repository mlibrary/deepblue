# frozen_string_literal: true
# hyrax-orcid

require 'rails_helper'

RSpec.describe ::OrcidIdentity, type: :model do
  let(:work_sync_preference) { { sync_all: 0, sync_notify: 1, manual: 2 } }

  it { is_expected.to validate_presence_of(:access_token) }
  it { is_expected.to validate_presence_of(:token_type) }
  it { is_expected.to validate_presence_of(:refresh_token) }
  it { is_expected.to validate_presence_of(:expires_in) }
  it { is_expected.to validate_presence_of(:scope) }
  it { is_expected.to validate_presence_of(:orcid_id) }
  it { is_expected.to define_enum_for(:work_sync_preference).with_values(work_sync_preference) }
  it { is_expected.to belong_to(:user).class_name("User") }
  it { is_expected.to have_many(:orcid_works) }

  describe "after create" do
    # let(:user) { create(:user) }

    context "without orcid id" do
      let(:user) { FactoryBot.build(:user) }

      it "doesn't have an orcid set by default" do
        expect(user.orcid).to be_nil
      end
    end

    context "with an orcid ID" do
      #let(:identity) { FactoryBot.create(:orcid_identity, user: user) }
      let(:user) { FactoryBot.create(:user, :with_orcid_identity ) }

      it "saves the orcid ID to the user on create" do
        # identity = create(:orcid_identity, user: user)
        # expect(user.orcid).to include(identity.orcid_id)
        expect(user.orcid).to_not be_nil
      end
    end
  end

end
