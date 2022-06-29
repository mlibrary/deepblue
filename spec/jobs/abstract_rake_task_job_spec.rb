# frozen_string_literal: true

require 'rails_helper'

class MockJobForAbstractRakeTaskJob < AbstractRakeTaskJob

end

RSpec.describe AbstractRakeTaskJob, skip: false do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it {  expect( described_class.abstract_rake_task_job_debug_verbose ).to eq debug_verbose }
  end

  let(:job) { MockJobForAbstractRakeTaskJob.new }
  let(:hostname_allowed) { [Rails.configuration.hostname] }

  before do
    allow(job).to receive(:verbose).and_return false
  end

  describe ".default_value_is" do
    let(:value) { 'some_value' }
    it { expect(job.default_value_is(nil)).to eq nil }
    it { expect(job.default_value_is(value)).to eq value }
    it { expect(job.default_value_is(value, nil)).to eq value }
    it { expect(job.default_value_is(nil, 'some_default')).to eq 'some_default' }
    it { expect(job.default_value_is(value, 'some_default')).to eq value }
  end

  describe ".email_exec_results" do
    it "is TODO" do
      skip "the test code goes here"
    end
  end

  describe ".event_name" do
    it "returns" do
      expect(job.event_name).to eq 'mock job for abstract rake task'
    end
  end

  describe ".initialize_from_args" do
    it "is TODO" do
      skip "the test code goes here"
    end
  end

  # describe ".options_value" do
  #   let(:key) { 'a_key' }
  #   let(:default_value ) { 'default' }
  #   before do
  #     expect(job).to receive(:options).and_return []
  #   end
  #   it "returns value" do
  #     expect(job).to receive(:job_options_value).with( key: key, default_value: default_value )
  #     job.options_value(key: key, default_value: default_value, task: false)
  #   end
  # end

  describe ".run_job_delay" do
    it "is TODO" do
      skip "the test code goes here"
    end
  end

  describe ".task_name" do
    it "returns" do
      expect(job.task_name).to eq 'Mock Job For Abstract Rake Task Job'
    end
  end

end
