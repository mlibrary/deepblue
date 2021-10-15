require 'rails_helper'

RSpec.describe DoiMintingJob do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( ::Deepblue::DoiMintingService.doi_minting_job_debug_verbose ).to eq( debug_verbose )
    end
  end

  let(:user) { create(:user) }

  RSpec.shared_examples 'it performs the job' do |doi_call_success, debug_verbose_count|
    let(:dbg_verbose) { debug_verbose_count > 0 }
    let(:data_set)    { create(:data_set_with_one_file, doi: ::Deepblue::DoiBehavior.doi_pending) }
    let(:job_delay)   { 0 }
    let(:target_url)  { nil }
    let(:job)         { described_class.send( :job_or_instantiate,
                                             data_set.id,
                                             current_user: user,
                                             job_delay: job_delay,
                                             target_url: target_url ) }

    before do
      expect(job).to receive(:perform_now).with(no_args).and_call_original
      # expect(::PersistHelper).to receive(:find).with(data_set.id).and_return data_set
      if doi_call_success
        expect(Hyrax.config.callback).to receive(:set?).with( :after_doi_success ).and_return false
      else
        expect(Hyrax.config.callback).to receive(:set?).with( :after_doi_failure ).and_return false
      end
      if 0 < debug_verbose_count
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(debug_verbose_count).times
      else
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug)
      end
      expect(User).to receive(:find_by_user_key).with(user).and_return user
    end

    it 'it performs the job' do
      save_debug_verbose = ::Deepblue::DoiMintingService.doi_minting_job_debug_verbose
      ::Deepblue::DoiMintingService.doi_minting_job_debug_verbose = dbg_verbose
      expect(::Deepblue::DoiMintingService.doi_minting_job_debug_verbose).to eq dbg_verbose
      expect(::Deepblue::DoiMintingService).to receive(:mint_doi_for).with( curation_concern: data_set,
                                                                            current_user: user,
                                                                            target_url: target_url,
                                                                            debug_verbose: dbg_verbose ).and_return doi_call_success
      ActiveJob::Base.queue_adapter = :test
      job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
      ::Deepblue::DoiMintingService.doi_minting_job_debug_verbose = save_debug_verbose
    end

  end

  describe 'run the job' do
    context 'normal and success' do
      doi_call_success = true
      debug_verbose_count = 0
      it_behaves_like 'it performs the job', doi_call_success, debug_verbose_count
    end
    context 'normal and failure' do
      doi_call_success = false
      debug_verbose_count = 0
      it_behaves_like 'it performs the job', doi_call_success, debug_verbose_count
    end
    context 'normal success with debug_verbose' do
      doi_call_success = true
      debug_verbose_count = 1
      it_behaves_like 'it performs the job', doi_call_success, debug_verbose_count
    end
  end

end
