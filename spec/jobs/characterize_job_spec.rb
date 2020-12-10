# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CharacterizeJob do

  DEBUG_VERBOSE = false

  before :all do
    if DEBUG_VERBOSE
      ::Deepblue::LoggingHelper.echo_to_puts = true
      ::Deepblue::IngestHelper.ingest_helper_debug_verbose = true
      CharacterizeJob.characterize_job_debug_verbose = true
    end
  end

  after :all do
    if DEBUG_VERBOSE
      ::Deepblue::LoggingHelper.echo_to_puts = false
      ::Deepblue::IngestHelper.ingest_helper_debug_verbose = false
      CharacterizeJob.characterize_job_debug_verbose = false
    end
  end

  let(:user) { create(:user) }
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
    allow(FileSet).to receive(:find).with(file_set_id).and_return(file_set)
    expect(::Deepblue::IngestHelper).to receive(:characterize).with( any_args ).and_call_original
    allow(CreateDerivativesJob).to receive(:perform_now).with(file_set, file.id, filename)
  end

  context 'with valid filepath param' do
    let(:filename) { File.join(fixture_path, 'world.png') }
    let(:job)      { described_class.send( :job_or_instantiate, file_set, file.id, filename ) }

    it 'skips Hyrax::WorkingDirectory' do
      # expect(Hyrax::WorkingDirectory).not_to receive(:find_or_retrieve)
      expect(::Deepblue::IngestHelper).not_to receive(:log_error).with( any_args )
      expect(::Deepblue::IngestHelper).to receive(:perform_create_derivatives_job).with( any_args ).and_call_original

      expect( job ).not_to receive(:log_error).with( any_args )
      job.perform_now
      expect( JobStatus.all.count ).to eq 1
      job_status = JobStatus.all.first
      expect( job_status.job_class ).to eq CharacterizeJob.name
      expect( job_status.status ).to eq "finished_characterize"
      expect( job_status.state ).to eq nil
      expect( job_status.message ).to eq nil
      expect( job_status.error ).to eq nil
    end
  end

  context 'when the characterization proxy content is present' do
    let(:job) { described_class.send( :job_or_instantiate, file_set, file.id ) }

    it 'runs Hydra::Works::CharacterizationService and creates a CreateDerivativesJob' do
      expect(::Deepblue::IngestHelper).not_to receive(:log_error).with( any_args )
      # expect(Hydra::Works::CharacterizationService).to receive(:run).with(file, filename)
      # expect(file).to receive(:save!)
      # expect(file_set).to receive(:update_index)
      expect(::Deepblue::IngestHelper).to receive(:perform_create_derivatives_job).with( any_args ).and_call_original
      # described_class.perform_now(file_set, file.id)

      expect( job ).not_to receive(:log_error).with( any_args )
      job.perform_now
      expect( JobStatus.all.count ).to eq 1
      job_status = JobStatus.all.first
      expect( job_status.job_class ).to eq CharacterizeJob.name
      expect( job_status.status ).to eq "finished_characterize"
      expect( job_status.message ).to eq nil
      expect( job_status.error ).to eq nil
    end
  end

  context 'when the characterization proxy content is absent' do
    let(:job) { described_class.send( :job_or_instantiate, file_set, file.id ) }

    before { allow(file_set).to receive(:characterization_proxy?).and_return(false) }
    it 'raises an error' do
      expect( job ).to receive(:log_error).with( any_args ).and_call_original
      job.perform_now
      expect( JobStatus.all.count ).to eq 1
      job_status = JobStatus.all.first
      # puts ">>>"
      # puts "job_status.error=#{job_status.error}"
      # puts "job_status.message=#{job_status.message}"
      # puts "<<<"
      expect( job_status.job_class ).to eq CharacterizeJob.name
      expect( job_status.status ).to eq nil
      expect( job_status.message ).to eq nil
      expect( job_status.error ).to start_with "original_file was not found"
    end
  end

end
