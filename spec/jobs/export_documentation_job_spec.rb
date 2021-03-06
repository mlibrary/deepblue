require 'rails_helper'

RSpec.describe ExportDocumentationJob do

  let(:debug_verbose)   {false}

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.export_documentation_job_debug_verbose ).to eq debug_verbose
    end
  end

  # context 'with valid arguments' do
  #   let(:event)   { 'heartbeat' }
  #   let(:args)    { {} }
  #   let(:job)     { described_class.send( :job_or_instantiate, *args ) }
  #   let(:options) { {} }
  #   let(:time_before) { DateTime.now }
  #
  #   before do
  #     expect(job).to receive(:perform_now).with(no_args).and_call_original
  #     expect(job).to receive(:job_status_init).with(no_args).and_call_original
  #     expect(job).to receive(:timestamp_begin).with(no_args).at_least(:once).and_call_original
  #     expect(job).to receive(:initialize_options_from).with({:debug_verbose=>debug_verbose}).and_call_original
  #     expect(job).to receive(:log).with({event: event})
  #   end
  #
  #   it 'it performs the job' do
  #     expect(job.hostname).to eq ::DeepBlueDocs::Application.config.hostname
  #     ActiveJob::Base.queue_adapter = :test
  #     job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
  #     time_after = DateTime.now
  #     expect(job.options).to eq options
  #     expect(job.verbose).to eq false
  #     expect(job.timestamp_begin.between?(time_before,time_after)).to eq true
  #     expect(job.job_status).to_not eq nil
  #     expect(job.job_status.status? JobStatus::FINISHED).to eq true
  #   end
  #
  # end

end
