# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContentDepositEventJob do

  let(:user)             { create(:user) }
  let(:mock_time)        { Time.zone.at(1) }
  let(:curation_concern) { create(:work, title: ['MacBeth'], user: user) }
  let(:event) do
    {
      action: "User <a href=\"/users/#{user.to_param}\">#{user.user_key}</a> "\
                "has deposited <a href=\"/concern/data_sets/#{curation_concern.id}\">MacBeth</a>",
      timestamp: '1'
    }
  end

  before do
    allow(Time).to receive(:now).at_least(:once).and_return(mock_time)
  end

  it "logs the event to the depositor's profile and the Work" do
    expect do
      described_class.perform_now(curation_concern, user)
    end.to change { user.profile_events.length }.by(1)
                                                .and change { curation_concern.events.length }.by(1)

    expect(user.profile_events.first).to eq(event)
    expect(curation_concern.events.first).to eq(event)
  end

end
