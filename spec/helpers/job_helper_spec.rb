# frozen_string_literal: true

require 'rails_helper'

class MockJobHelper
  include JobHelper
end

RSpec.describe JobHelper, type: :helper do

  let(:message1) { "Message Number 1." }

  describe '#job_options_keys_found' do
    subject { MockJobHelper.new }

    it "job_options_keys_found default" do
      expect( subject.job_options_keys_found ).to eq []
    end

  end

  describe '#job_options_value', skip: true do
    subject { MockJobHelper.new }

    it "job_options_value" do
      expect( subject.job_options_keys_found ).to eq []
    end

  end

  describe "#queue_msg_if?", skip: false do
    subject { MockJobHelper.new }

    it "updates the queue if test_result is true" do
      test_result = true
      expect( subject.queue_msg_if?( test_result, message1 ) ).to eq test_result
      expect( subject.job_msg_queue ).to eq [message1]
    end

    it "does not update the queue if test_result is false" do
      test_result = false
      expect( subject.queue_msg_if?( test_result, message1 ) ).to eq test_result
      expect( subject.job_msg_queue ).to eq []
    end

  end

  describe "#queue_msg_unless?", skip: false do
    subject { MockJobHelper.new }

    it "updates the queue if test_result is false" do
      test_result = false
      expect( subject.queue_msg_unless?( test_result, message1 ) ).to eq test_result
      expect( subject.job_msg_queue ).to eq [message1]
    end

    it "does not update the queue if test_result is true" do
      test_result = true
      expect( subject.queue_msg_unless?( test_result, message1 ) ).to eq test_result
      expect( subject.job_msg_queue ).to eq []
    end

  end

end
