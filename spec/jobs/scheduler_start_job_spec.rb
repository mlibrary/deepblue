# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchedulerStartJob, skip: false do

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.scheduler_start_job_debug_verbose ).to eq( false )
    end
  end

  context 'with valid arguments and scheduler running' do
    let(:job_delay) { 0 }
    let(:restart)   { false }
    let(:options)   { {} }
    let(:job)       { described_class.send( :job_or_instantiate,
                                            job_delay: job_delay,
                                            restart: restart,
                                            **options ) }
    let(:hostname)  { DeepBlueDocs::Application.config.hostname }
    let(:sched_pid) { 123 }

    before do
      expect( described_class.scheduler_start_job_debug_verbose ).to eq false
      expect( job ).to receive( :delay_job ).with( job_delay )
      expect( job ).to receive( :scheduler_pid ).with( no_args ).and_return sched_pid
      expect( job ).to receive( :hostname ).with( no_args ).and_return hostname
      expect( job ).to receive( :scheduler_emails ).with( subject: "DBD scheduler already running on #{hostname}" )
    end

    it 'calls update_current_month_condensed_events' do
      ActiveJob::Base.queue_adapter = :test
      job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
    end
  end

end
