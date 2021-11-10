require 'rails_helper'

class MockIngestJob < AbstractIngestJob

  def perform(parent_job_id:, user_id:, verbose:)
    find_or_create_job_status_started( parent_job_id: parent_job_id, user_id: user_id, verbose: verbose )
  end

  def id
    "mock_id"
  end

end

RSpec.describe AbstractIngestJob do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.abstract_ingest_job_debug_verbose ).to eq( debug_verbose ) }
  end

  describe '.find_or_create_job_status_started' do
    let(:current_user) { create(:user) }
    let(:parent_job_id) { nil }
    let(:continue_job_chain_later) { false }
    let(:verbose)    { false }
    let(:main_cc_id) { nil }
    let(:user_id)    { current_user.id }
    let(:job)        { MockIngestJob.send( :job_or_instantiate,
                                           parent_job_id: parent_job_id,
                                           user_id: user_id,
                                           verbose: verbose ) }
    let(:job_status) { IngestJobStatus.new( job_id: job.id,
                                            verbose: verbose,
                                            main_cc_id: main_cc_id,
                                            user_id: user_id  ) }

    before do
      expect(job).to receive(:find_or_create_job_status_started).with( parent_job_id: parent_job_id,
                                                                       user_id: user_id,
                                                                       verbose: verbose ).and_call_original
      expect(IngestJobStatus).to receive(:find_or_create_job_started).with( job: job,
                                                  parent_job_id: parent_job_id,
                                                  continue_job_chain_later: continue_job_chain_later,
                                                  verbose: verbose,
                                                  main_cc_id: main_cc_id,
                                                  user_id: user_id  ).and_return job_status
    end

    it "calls method" do
      expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug)
      job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
    end

    it "calls method and debug verbose is true" do
      expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(2).times
      save_debug_verbose = MockIngestJob.abstract_ingest_job_debug_verbose
      MockIngestJob.abstract_ingest_job_debug_verbose = true
      job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
      expect(job.job_status).to eq job_status
      MockIngestJob.abstract_ingest_job_debug_verbose = save_debug_verbose
    end

  end

  it ".log_error" do
    skip "the test code goes here"
  end

  describe '.user_id_from' do

    # return nil if current_user.blank?
    # return current_user.id if current_user.respond_to? :id
    # email = current_user
    # email = current_user.user_key if current_user.respond_to? :user_key
    # user = User.find_by_user_key email
    # return nil if user.blank?
    # user.id

    it ".user_id_from" do
      skip "the test code goes here"
    end
  end

end
