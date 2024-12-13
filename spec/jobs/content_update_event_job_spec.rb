# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContentUpdateEventJob do
  let(:user) { factory_bot_create_user(:user) }
  let(:mock_time) { Time.zone.at(1) }
  let(:curation_concern) { create(:file_set, title: ['Hamlet'], user: user) }
  let(:event) do
    {
      action: "User <a href=\"/users/#{user.to_param}\">#{user.user_key}</a> "\
              "has updated <a href=\"/concern/file_sets/#{curation_concern.id}\">Hamlet</a>",
      timestamp: '1'
    }
  end

  before do
    allow(Time).to receive(:now).at_least(:once).and_return(mock_time)
  end

  it "logs the event to the depositor's profile and the FileSet" do
    expect do
      described_class.perform_now(curation_concern, user)
    end.to change { user.profile_events.length }.by(1)
                                                .and change { curation_concern.events.length }.by(1)

    expect(user.profile_events.first).to eq(event)
    expect(curation_concern.events.first).to eq(event)
  end
end
