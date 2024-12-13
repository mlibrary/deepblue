# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchedulerStartJob, skip: false do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.scheduler_start_job_debug_verbose ).to eq( debug_verbose ) }
  end

  describe 'all', skip: false do
    RSpec.shared_examples 'shared SchedulerStartJob' do |dbg_verbose|
      subject { described_class }
      before do
        described_class.scheduler_start_job_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose
      end
      after do
        described_class.scheduler_start_job_debug_verbose = debug_verbose
      end
      context do

        let(:autostart) { false }
        let(:job_delay) { 0 }
        let(:restart)   { false }
        let(:options)   { {} }
        let(:user)      { factory_bot_create_user(:user) }
        let(:job)       { described_class.send( :job_or_instantiate,
                                                autostart: autostart,
                                                job_delay: job_delay,
                                                restart: restart,
                                                user_email: user.email,
                                                options: options ) }

        context 'with valid arguments and scheduler running' do
          let(:hostname)  { Rails.configuration.hostname }
          let(:sched_pid) { 123 }
          let(:email_msg) { "DBD scheduler already running on #{hostname}" }

          before do
            allow( ::Deepblue::SchedulerIntegrationService ).to receive(:scheduler_active).and_return true
            expect(job).to receive(:perform_now).with(any_args).and_call_original
            expect( job ).to receive( :delay_job ).with( job_delay )
            allow( job ).to receive( :scheduler_pid ).with( no_args ).and_return sched_pid
            expect( job ).to receive( :hostname ).with( no_args ).and_return hostname
            expect( job ).to receive( :scheduler_emails ) do |args|
              expect(args[:autostart]).to eq current_user
              expect(args[:to]).to eq [user.email]
            end.and_call_original
            #.with( autostart: autostart, to: [user.email], subject: email_msg, body: email_msg )
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
            expect( job.hostname ).to eq Rails.configuration.hostname
            ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
          end
        end
      end
    end
    it_behaves_like 'shared SchedulerStartJob', false
    it_behaves_like 'shared SchedulerStartJob', true
  end

end
