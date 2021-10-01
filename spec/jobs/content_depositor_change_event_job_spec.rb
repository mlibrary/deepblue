# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContentDepositorChangeEventJob, skip: false do

  let(:user)         { create(:user) }
  let(:another_user) { create(:user) }
  let(:data_set)     { create(:data_set, title: ['BethsMac'], user: user) }
  let(:mock_time)    { Time.zone.at(1) }
  let(:event) do
    { action: "User <a href=\"/users/#{user.to_param}\">#{user.user_key}</a> " \
                          "has transferred <a href=\"/concern/data_sets/#{data_set.id}\">BethsMac</a> " \
                          "to user <a href=\"/users/#{another_user.to_param}\">#{another_user.user_key}</a>",
      timestamp: '1' }
  end

  before do
    allow(Time).to receive(:now).at_least(:once).and_return(mock_time)
  end

  it "logs the event to the proxy depositor's profile, the depositor's dashboard, and the FileSet" do
    expect do
      described_class.perform_now(data_set, another_user)
    end.to change { user.profile_events.length }.by(1)
                                                .and change { another_user.events.length }.by(1)
                                                .and change { data_set.events.length }.by(1)

    expect(user.profile_events.first).to eq(event)
    expect(another_user.events.first).to eq(event)
    expect(data_set.events.first).to eq(event)
  end

end
