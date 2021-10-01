# frozen_string_literal: true

require 'rails_helper'

class TestEventJob < EventJob

  def action
    @action ||= "Test Event occured"
  end

end

RSpec.describe EventJob do

  let(:user)      { create(:user) }
  let(:mock_time) { Time.zone.at(1) }
  let(:event) do
    {
      action: "Test Event occured",
      timestamp: '1'
    }
  end

  before do
    allow(Time).to receive(:now).and_return(mock_time)
  end

  context 'standard event' do
    it "logs the event to the depositor's profile" do
      expect do
        TestEventJob.perform_now(user)
      end.to change { user.events.length }.by(1)
      expect(user.events.first).to eq(event)
    end
  end

end
