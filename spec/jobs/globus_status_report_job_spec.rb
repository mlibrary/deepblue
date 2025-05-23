require 'rails_helper'

RSpec.configure do |config|
  config.filter_run_excluding globus_export: :true unless ::Deepblue::GlobusIntegrationService.globus_export
end

RSpec.describe GlobusStatusReportJob, "GlobusJob globus_export: :true", globus_export: :true do

  let(:debug_verbose)   {false}

  describe 'module debug verbose variables' do
    it { expect( ::Deepblue::JobTaskHelper.globus_status_report_job_debug_verbose ).to eq debug_verbose }
  end

  describe 'defines scheduler entry' do
    it 'has scheduler entry' do
      expect( described_class::SCHEDULER_ENTRY ).to include( "class: #{described_class.name}" )
    end
  end

  describe 'all', skip: false do
    RSpec.shared_examples 'shared GlobusStatusReportJob' do |dbg_verbose|
      subject { described_class }
      before do
        ::Deepblue::JobTaskHelper.globus_status_report_job_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose
      end
      after do
        ::Deepblue::JobTaskHelper.globus_status_report_job_debug_verbose = debug_verbose
      end
      context 'with valid arguments' do
        let(:event)   { 'globus status report job' }
        let(:args)    { {} }
        let(:job)     { described_class.send(:job_or_instantiate, **args) }
        let(:options) { {} }
        let(:time_before) { DateTime.now }

        before do
          expect(job).to receive(:perform_now).with(no_args).and_call_original
          expect(job).to receive(:job_status_init).with(id: nil, restartable: nil).and_call_original
          expect(job).to receive(:timestamp_begin).with(no_args).at_least(:once).and_call_original
          expect(job).to receive(:initialize_options_from).with(args: [], debug_verbose: dbg_verbose).and_call_original
          expect(job).to receive(:log).with({event: event, hostname_allowed: true})
        end

        it 'it performs the job' do
          expect(job.hostname).to eq Rails.configuration.hostname
          ActiveJob::Base.queue_adapter = :test
          job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
          time_after = DateTime.now
          expect(job.options).to eq options
          expect(job.verbose).to eq false
          expect(job.timestamp_begin.between?(time_before,time_after)).to eq true
          expect(job.job_status).to_not eq nil
          expect(job.job_status.status? JobStatus::FINISHED).to eq true
        end

      end
    end
    it_behaves_like 'shared GlobusStatusReportJob', false
    it_behaves_like 'shared GlobusStatusReportJob', true
  end


end
