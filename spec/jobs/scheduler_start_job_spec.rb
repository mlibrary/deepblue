# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchedulerStartJob, skip: false do

  let(:job_delay) { 0 }
  let(:restart)   { false }
  let(:options)   { {} }
  let(:user)      { create(:user) }
  let(:job)       { described_class.send( :job_or_instantiate,
                                          job_delay: job_delay,
                                          restart: restart,
                                          user_email: user.email,
                                          **options ) }

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.scheduler_start_job_debug_verbose ).to eq( false )
    end
  end

  context 'with valid arguments and scheduler running' do
    let(:hostname)  { ::DeepBlueDocs::Application.config.hostname }
    let(:sched_pid) { 123 }
    let(:email_msg) { "DBD scheduler already running on #{hostname}" }

    before do
      expect( described_class.scheduler_start_job_debug_verbose ).to eq false
      expect( job ).to receive( :delay_job ).with( job_delay )
      expect( job ).to receive( :scheduler_pid ).with( no_args ).and_return sched_pid
      expect( job ).to receive( :hostname ).with( no_args ).and_return hostname
      expect( job ).to receive( :scheduler_emails ).with( to: [user.email], subject: email_msg, body: email_msg )
    end

    it 'starts the scheduler' do
      ActiveJob::Base.queue_adapter = :test
      job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
    end

    after do
      expect( job.rails_bin_scheduler ).to eq Rails.application.root.join( 'bin', 'scheduler.sh' ).to_s
      expect( job.rails_log_scheduler ).to eq Rails.application.root.join( 'log', 'scheduler.sh.out' ).to_s
    end

  end

  describe '.hostname' do
    it 'returns the application hostname' do
      expect( job.hostname ).to eq ::DeepBlueDocs::Application.config.hostname
    end
  end

end
