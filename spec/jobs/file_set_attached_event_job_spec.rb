# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FileSetAttachedEventJob, skip: false do

  let(:user) { factory_bot_create_user(:user) }
  let(:mock_time) { Time.zone.at(1) }

  before do
    allow_any_instance_of(User).to receive(:can?).and_return(true)
    allow(Time).to receive(:now).at_least(:once).and_return(mock_time)
  end

  context 'with a FileSet' do
    let(:file_set) { curation_concern.file_sets.first }
    let(:curation_concern) { create(:data_set_with_one_file, title: ['MacBeth'], user: user) }
    let(:event) do
      {
        action: "User <a href=\"/users/#{user.to_param}\">#{user.user_key}</a> " \
                "has attached <a href=\"/concern/file_sets/#{file_set.id}\">A Contained FileSet</a> " \
                "to <a href=\"/concern/data_sets/#{curation_concern.id}\">MacBeth</a>",
        timestamp: '1'
      }
    end

    it "logs the event to the right places" do
      expect do
        described_class.perform_now(file_set, user)
      end.to change { user.profile_events.length }.by(1)
                      .and change { file_set.events.length }.by(1)
                      .and change { curation_concern.events.length }.by(1)

      expect(user.profile_events.first).to eq(event)
      expect(curation_concern.events.first).to eq(event)
      expect(file_set.events.first).to eq(event)
    end

  end

end
