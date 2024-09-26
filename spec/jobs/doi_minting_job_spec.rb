require 'rails_helper'

RSpec.describe DoiMintingJob, skip: true do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( ::Deepblue::DoiMintingService.doi_minting_job_debug_verbose ).to eq debug_verbose }
  end

  let(:user) { create(:user) }

  RSpec.shared_examples 'it performs the job' do |doi, doi_mint_called, doi_call_success, debug_verbose_count|
    let(:dbg_verbose) { debug_verbose_count > 0 }
    # let(:data_set)    { create(:data_set_with_one_file, doi: ::Deepblue::DoiBehavior.doi_pending_init) }
    let(:data_set)    { create(:data_set_with_one_file, doi: doi) }
    let(:job_delay)   { 0 }
    let(:target_url)  { nil }
    let(:job)         { described_class.send( :job_or_instantiate,
                                              id: data_set.id,
                                              current_user: user,
                                              job_delay: job_delay,
                                              target_url: target_url ) }

    before do
      expect(job).to receive(:perform_now).with(no_args).and_call_original
      # expect(::PersistHelper).to receive(:find).with(data_set.id).and_return data_set
      if doi_mint_called && doi_call_success
        expect(Hyrax.config.callback).to receive(:set?).with( :after_doi_success ).and_return false
      elsif doi_mint_called && !doi_call_success
        expect(Hyrax.config.callback).to receive(:set?).with( :after_doi_failure ).and_return false
      end
      if 0 < debug_verbose_count
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(debug_verbose_count).times
      else
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug)
      end
      if doi_mint_called
        expect(User).to receive(:find_by_user_key).with(user).and_return user
      end
    end

    it 'it performs the job' do
      save_debug_verbose = ::Deepblue::DoiMintingService.doi_minting_job_debug_verbose
      ::Deepblue::DoiMintingService.doi_minting_job_debug_verbose = dbg_verbose
      expect(::Deepblue::DoiMintingService.doi_minting_job_debug_verbose).to eq dbg_verbose
      if doi_mint_called
        expect(::Deepblue::DoiMintingService).to receive(:mint_doi_for).with( curation_concern: data_set,
                                                                            current_user: user,
                                                                            target_url: target_url,
                                                                            debug_verbose: dbg_verbose ).and_return doi_call_success
      else
        expect(::Deepblue::DoiMintingService).not_to receive(:mint_doi_for)
      end
      ActiveJob::Base.queue_adapter = :test
      job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
      ::Deepblue::DoiMintingService.doi_minting_job_debug_verbose = save_debug_verbose
    end

  end

  describe 'run the job' do
    context 'normal and success' do
      doi = nil
      doi_mint_called = true
      doi_call_success = true
      debug_verbose_count = 0
      it_behaves_like 'it performs the job', doi, doi_mint_called, doi_call_success, debug_verbose_count
    end
    context 'pending' do
      doi = ::Deepblue::DoiBehavior.doi_pending_init
      doi_mint_called = false
      doi_call_success = true
      debug_verbose_count = 0
      it_behaves_like 'it performs the job', doi, doi_mint_called, doi_call_success, debug_verbose_count
    end
    context 'pending with timeout' do
      doi = ::Deepblue::DoiBehavior.doi_pending_init( as_of: DateTime.now - 1.day )
      doi_mint_called = true
      doi_call_success = true
      debug_verbose_count = 0
      it_behaves_like 'it performs the job', doi, doi_mint_called, doi_call_success, debug_verbose_count
    end
    context 'normal and failure' do
      doi = nil
      doi_mint_called = true
      doi_call_success = false
      debug_verbose_count = 0
      it_behaves_like 'it performs the job', doi, doi_mint_called, doi_call_success, debug_verbose_count
    end
    context 'normal success with debug_verbose' do
      doi = nil
      doi_mint_called = true
      doi_call_success = true
      debug_verbose_count = 1
      it_behaves_like 'it performs the job', doi, doi_mint_called, doi_call_success, debug_verbose_count
    end
  end

end
