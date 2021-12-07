require 'rails_helper'

class MockDeepblueJob < ::Deepblue::DeepblueJob

  def perform

  end

end

RSpec.describe ::Deepblue::DeepblueJob do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.deepblue_job_debug_verbose ).to eq debug_verbose }
  end

  describe '.email_all_targets' do
    it "is TODO" do
      skip "the test code goes here"
    end
  end

  describe '.find_all_email_targets' do
    let(:job) { described_class.new }
    let(:email_target1) { 'emailTarget1' }
    let(:email_target2) { 'emailTarget2' }
    let(:email_target_redundant) { email_target1 }

    let(:email_targets) { [email_target1] }
    let(:additional_email_targets) { [email_target2,email_target_redundant] }
    before do
      job.email_targets = email_targets
    end
    it "it combines parms" do
      expect(job.email_targets).to eq email_targets
      job.find_all_email_targets( additional_email_targets: additional_email_targets )
      expect(job.email_targets).to eq [email_target1,email_target2]
    end
  end

  describe '.hostname_allowed' do
    let(:job) { described_class.new }

    it "calls job task helper" do
      expect(::Deepblue::JobTaskHelper).to receive(:hostname_allowed).with(any_args).and_return true
      expect(job.hostname_allowed).to eq true
    end
  end

end
