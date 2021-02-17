# frozen_string_literal: true

require 'rails_helper'

class MockJobForAbstractRakeTaskJob < AbstractRakeTaskJob

end

RSpec.describe AbstractRakeTaskJob, skip: false do

  let(:job) { MockJobForAbstractRakeTaskJob.new }
  let(:hostname_allowed) { [::DeepBlueDocs::Application.config.hostname] }

  before do
    allow( job ).to receive(:verbose).and_return false
  end

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.abstract_rake_task_job_debug_verbose ).to eq( false )
    end
  end

  describe ".default_value_is" do
    it "is TODO" do
      skip "the test code goes here"
    end
  end

  describe ".email_exec_results" do
    it "is TODO" do
      skip "the test code goes here"
    end
  end

  describe ".initialize_from_args" do
    it "is TODO" do
      skip "the test code goes here"
    end
  end

  describe ".run_job_delay" do
    it "is TODO" do
      skip "the test code goes here"
    end
  end

end
