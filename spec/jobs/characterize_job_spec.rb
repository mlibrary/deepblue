# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CharacterizeJob do

  mattr_accessor :spec_characterize_job_debug_verbose, default: false

  before :all do
    if spec_characterize_job_debug_verbose
      ::Deepblue::LoggingHelper.echo_to_puts = true
      ::Deepblue::IngestHelper.ingest_helper_debug_verbose = true
      AbstractIngestJob.abstract_ingest_job_debug_verbose = true
      CharacterizeJob.characterize_job_debug_verbose = true
      JobStatus.job_status_debug_verbose = true
    end
  end

  after :all do
    if spec_characterize_job_debug_verbose
      ::Deepblue::LoggingHelper.echo_to_puts = false
      ::Deepblue::IngestHelper.ingest_helper_debug_verbose = false
      CharacterizeJob.characterize_job_debug_verbose = false
      AbstractIngestJob.abstract_ingest_job_debug_verbose = false
      JobStatus.job_status_debug_verbose = false
    end
  end

  describe 'module debug verbose variables' do
    it { expect( described_class.characterize_job_debug_verbose ).to eq false }
  end

  describe 'fits exists' do
    it { expect(Hyrax.config.fits_path.present?).to eq true }
    it { expect(`which #{Hyrax.config.fits_path}_does_not_exist`.blank?).to eq true }
    it { expect(`which #{Hyrax.config.fits_path}`.present?).to eq true }
  end
  
  # skip because libreoffice is not installed in circleci
  describe 'libreoffice exists', skip: ENV['CIRCLECI'].present? do
    it { expect(Hyrax.config.libreoffice_path.present?).to eq true }
    it { expect(`which #{Hyrax.config.libreoffice_path}_does_not_exist`.blank?).to eq true }
    it { expect(`which #{Hyrax.config.libreoffice_path}`.present?).to eq true }
  end

  # let(:user) { create(:user) }
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let(:file_set_id) { 'abc12345' }
  let(:filename)    { Rails.root.join('tmp', 'uploads', 'ab', 'c1', '23', '45', 'abc12345', 'picture.png').to_s }
  let(:file_set) do
    FileSet.new(id: file_set_id).tap do |fs|
      allow(fs).to receive(:original_file).and_return(file)
      allow(fs).to receive(:update_index)
    end
  end
  # let(:io)          { JobIoWrapper.new(file_set_id: file_set.id, user: create(:user), path: filename) }
  let(:file) do
    Hydra::PCDM::File.new.tap do |f|
      f.content = 'foo'
      f.original_name = 'picture.png'
      f.save!
      allow(f).to receive(:save!)
    end
  end

  before do
    puts "user1=#{user1}, user1.id=#{user1.id}" if spec_characterize_job_debug_verbose
    puts "user2=#{user2}, user2.id=#{user2.id}" if spec_characterize_job_debug_verbose
    puts "user3=#{user3}, user3.id=#{user3.id}" if spec_characterize_job_debug_verbose

    allow(FileSet).to receive(:find).with(file_set_id).and_return(file_set)
    # TODO: need to be able to find the job status, so use the user_id to find it
    # allow(CreateDerivativesJob).to receive(:perform_now).with(file_set, file.id, filename)
  end

  context 'with valid filepath param' do
    let(:filename) { File.join(fixture_path, 'world.png') }
    let(:job)      { described_class.send( :job_or_instantiate,
                                           file_set,
                                           file.id,
                                           filename,
                                           current_user: current_user.user_key ) }
    let(:current_user) { user1 }

    before do
      ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here,
                                            "file_set.id=#{file_set.id}",
                                            "file.id=#{file.id}",
                                            "file_name=#{file.id}",
                                            "current_user.id=#{current_user.id}",
                                            "current_user.email=#{current_user.email}",
                                            "" ] if spec_characterize_job_debug_verbose
      allow( CreateDerivativesJob ).to receive(:perform_now).with( file_set,
                                                                   file.id,
                                                                   filename,
                                                                   current_user: current_user.user_key ).and_call_original
      expect(::Deepblue::IngestHelper).to receive(:characterize).with( any_args ).and_call_original
    end

    it 'skips Hyrax::WorkingDirectory' do
      # expect(Hyrax::WorkingDirectory).not_to receive(:find_or_retrieve)
      expect(::Deepblue::IngestHelper).not_to receive(:log_error).with( any_args )
      expect(::Deepblue::IngestHelper).to receive(:perform_create_derivatives_job).with( any_args ).and_call_original

      expect(job).to receive(:perform_now).with(no_args).and_call_original
      expect(job).not_to receive(:log_error).with( any_args )

      ActiveJob::Base.queue_adapter = :test
      job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
      expect( JobStatus.all.count ).to be_nonzero
      job_status = JobStatus.all.select { |j| j.user_id == current_user.id }
      expect( job_status ).not_to eq nil
      # job_status = JobStatus.all.select do |j|
      #   ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here,
      #                                         ::Deepblue::LoggingHelper.called_from,
      #                                         "j=#{j}",
      #                                         "j.job_id=#{j.job_id}",
      #                                         "j.parent_job_id=#{j.parent_job_id}",
      #                                         "j.message=#{j.message}",
      #                                         "j.error=#{j.error}",
      #                                         "j.user_id=#{j.user_id}",
      #                                         "current_user.id=#{current_user.id}",
      #                                         "current_user.email=#{current_user.email}",
      #                                         "" ] if spec_characterize_job_debug_verbose
      #
      #   j.user_id == current_user.id
      # end
      job_status = job_status.first
      expect(job_status.job_class).to eq CharacterizeJob.name
      expect(job_status.job_id).to eq job.job_id
      expect(job_status.parent_job_id).to eq nil
      expect(job_status.error).to eq nil
      expect(job_status.message).to eq nil
      expect(job_status.user_id).to eq current_user.id
      expect(job_status.main_cc_id).to eq nil
      #expect(job_status)
      expect( job_status.status ).to eq IngestJobStatus::FINISHED_CHARACTERIZE
      expect( job_status.state ).to eq nil
      if spec_characterize_job_debug_verbose
        expect( job_status.message ).to eq "did? finished_characterize returning false because current status is blank\nstatus changed to: finished_characterize"
      else
        expect( job_status.message ).to eq nil
      end
      expect( job_status.error ).to eq nil
    end
  end

  context 'when the characterization proxy content is present' do
    let(:job) { described_class.send( :job_or_instantiate, file_set, file.id, current_user: current_user.user_key ) }
    let(:current_user) { user2 }

    before do
      ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here,
                                            "file_set.id=#{file_set.id}",
                                            "file.id=#{file.id}",
                                            "file_name=#{file.id}",
                                            "current_user.id=#{current_user.id}",
                                            "current_user.email=#{current_user.email}",
                                            "" ] if spec_characterize_job_debug_verbose
      allow( job ).to receive(:perform_now).with( any_args ).and_call_original
      expect(::Deepblue::IngestHelper).to receive(:characterize).with( any_args ).and_call_original
    end

    it 'runs Hydra::Works::CharacterizationService and creates a CreateDerivativesJob' do
      expect(::Deepblue::IngestHelper).not_to receive(:log_error).with( any_args )
      # expect(Hydra::Works::CharacterizationService).to receive(:run).with(file, filename)
      # expect(file).to receive(:save!)
      # expect(file_set).to receive(:update_index)
      expect(::Deepblue::IngestHelper).to receive(:perform_create_derivatives_job).with( any_args ).and_call_original
      # described_class.perform_now(file_set, file.id)

      expect( job ).not_to receive(:log_error).with( any_args )
      ActiveJob::Base.queue_adapter = :test
      job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
      expect( JobStatus.all.count ).to be_nonzero
      job_status = JobStatus.all.select { |j| j.user_id == current_user.id }
      expect( job_status ).not_to eq nil
      job_status = job_status.first
      expect( job_status.job_class ).to eq CharacterizeJob.name
      expect( job_status.status ).to eq "finished_characterize"
      if spec_characterize_job_debug_verbose
        expect( job_status.message ).to eq "did? finished_characterize returning false because current status is blank\nstatus changed to: finished_characterize"
      else
        expect( job_status.message ).to eq nil
      end
      expect( job_status.error ).to eq nil
    end
  end

  context 'when the characterization proxy content is absent' do
    let(:job) { described_class.send( :job_or_instantiate, file_set, file.id, current_user: current_user.user_key ) }
    let(:current_user) { user3 }

    before do
      ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here,
                                            "file_set.id=#{file_set.id}",
                                            "file.id=#{file.id}",
                                            "file_name=#{file.id}",
                                            "current_user.id=#{current_user.id}",
                                            "current_user.email=#{current_user.email}",
                                            "" ] if spec_characterize_job_debug_verbose
      allow( job ).to receive(:perform_now).with( any_args ).and_call_original
      allow(file_set).to receive(:characterization_proxy?).and_return(false)
      expect(::Deepblue::IngestHelper).to receive(:characterize).with( any_args ).and_call_original
    end

    it 'raises an error' do
      expect( job ).to receive(:log_error).with( any_args ).and_call_original
      ActiveJob::Base.queue_adapter = :test
      job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
      expect( JobStatus.all.count ).to be_nonzero
      job_status = JobStatus.all.select { |j| j.user_id == current_user.id }
      expect( job_status ).not_to eq nil
      job_status = job_status.first
      # puts ">>>"
      # puts "job_status.error=#{job_status.error}"
      # puts "job_status.message=#{job_status.message}"
      # puts "<<<"
      expect( job_status.job_class ).to eq CharacterizeJob.name
      expect( job_status.status ).to eq nil
      if spec_characterize_job_debug_verbose
        expect( job_status.message ).to start_with "original_file was not found\nCharacterizeJob.perform(No Title"
      else
        expect( job_status.message ).to eq nil
      end
      expect( job_status.error ).to start_with "original_file was not found"
    end
  end

end
