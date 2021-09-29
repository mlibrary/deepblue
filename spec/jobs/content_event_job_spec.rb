require 'rails_helper'

class TestContentEventJob < ContentEventJob
end

RSpec.describe ContentEventJob do

  let(:dummy_class) { double }
  let(:dummy2_class) { double }

  it "logs event" do
  	allow(dummy_class).to receive(:log_event).and_return true
    event_job = TestContentEventJob.new dummy_class, dummy2_class
   	allow(event_job).to receive(:action).and_return "create"
   	allow(dummy2_class).to receive(:log_profile_event).and_return true
   	allow(Hyrax::Event ).to receive(:create).and_return "create"

    dc = event_job.perform dummy_class, dummy2_class

    expect(dc).to eq(true)
  end


  it "logs event" do
  	allow(dummy_class).to receive(:log_event).and_return true
    event_job = TestContentEventJob.new dummy_class, dummy2_class
   	allow(event_job).to receive(:action).and_return "create"
   	allow(Hyrax::Event ).to receive(:create).and_return "create"

    dc = event_job.log_event dummy_class

    expect(dc).to eq(true)
  end

  it "logs user event" do
  	allow(dummy_class).to receive(:log_profile_event).and_return true
    event_job = TestContentEventJob.new dummy_class, dummy2_class
   	allow(event_job).to receive(:action).and_return "create"
   	allow(Hyrax::Event ).to receive(:create).and_return "create"

    dc = event_job.log_user_event dummy_class

    expect(dc).to eq(true)
  end

end
