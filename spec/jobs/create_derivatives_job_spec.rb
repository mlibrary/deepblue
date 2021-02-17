# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreateDerivativesJob do

  SPEC_CREATE_DERIVATIVES_JOB_DEBUG_VERBOSE = false

  before :all do
    if SPEC_CREATE_DERIVATIVES_JOB_DEBUG_VERBOSE
      ::Deepblue::LoggingHelper.echo_to_puts = true
      ::Deepblue::IngestHelper.ingest_helper_debug_verbose = true
      CreateDerivativesJob.create_derivatives_job_debug_verbose = true
    end
  end

  after :all do
    if SPEC_CREATE_DERIVATIVES_JOB_DEBUG_VERBOSE
      ::Deepblue::LoggingHelper.echo_to_puts = false
      ::Deepblue::IngestHelper.ingest_helper_debug_verbose = false
      CreateDerivativesJob.create_derivatives_job_debug_verbose = false
    end
  end

  let(:user) { create(:user) }

  around do |example|
    ffmpeg_enabled = Hyrax.config.enable_ffmpeg
    Hyrax.config.enable_ffmpeg = true
    example.run
    Hyrax.config.enable_ffmpeg = ffmpeg_enabled
  end

  context "with an audio file" do
    let(:id)       { '123' }
    let(:file_set) { FileSet.new }

    let(:file) do
      Hydra::PCDM::File.new.tap do |f|
        f.content = 'foo'
        f.original_name = 'picture.png'
        f.save!
      end
    end

    before do
      allow(FileSet).to receive(:find).with(id).and_return(file_set)
      allow(file_set).to receive(:id).and_return(id)
      allow(file_set).to receive(:mime_type).and_return('audio/x-wav')
    end

    context "with a file name" do
      it 'calls create_derivatives and save on a file set' do
        expect(Hydra::Derivatives::AudioDerivatives).to receive(:create)
        expect(file_set).to receive(:reload)
        expect(file_set).to receive(:update_index)
        expect(::Deepblue::IngestHelper).to receive(:create_derivatives).with( any_args ).and_call_original
        described_class.perform_now(file_set, file.id)
        expect( JobStatus.all.count ).to eq 1
        job_status = JobStatus.all.first
        expect( job_status.job_class ).to eq CreateDerivativesJob.name
        expect( job_status.status ).to eq "delete_file"
        state = job_status.state_deserialize
        expect( state ).to eq nil
        expect( job_status.state ).to eq nil
        expect( job_status.message ).to eq nil
        puts "job_status.error='#{job_status.error}'" if SPEC_CREATE_DERIVATIVES_JOB_DEBUG_VERBOSE
        expect( job_status.error ).to eq nil
      end
    end

    context 'with a parent object' do
      before do
        allow(file_set).to receive(:parent).and_return(parent)
        # Stub out the actual derivative creation
        allow(file_set).to receive(:create_derivatives)
      end

      context 'when the file_set is the thumbnail of the parent' do
        let(:parent) { DataSet.new(thumbnail_id: id) }
        let(:job) { described_class.send( :job_or_instantiate, file_set, file.id, current_user: user ) }

        it 'updates the index of the parent object' do

          expect(::Deepblue::IngestHelper).not_to receive(:log_error).with( any_args )

          expect(file_set).to receive(:reload)
          expect(parent).to receive(:update_index)
          expect(::Deepblue::IngestHelper).to receive(:create_derivatives).with( any_args ).and_call_original
          #described_class.perform_now(file_set, file.id)

          expect(job).to receive(:perform_now).with(no_args).and_call_original
          expect(job).not_to receive(:log_error).with( any_args )

          ActiveJob::Base.queue_adapter = :test
          job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
          expect( JobStatus.all.count ).to eq 1
          job_status = JobStatus.all.first
          expect( job_status.job_class ).to eq CreateDerivativesJob.name
          expect(job_status.job_id).to eq job.job_id
          expect(job_status.parent_job_id).to eq nil
          expect(job_status.error).to eq nil
          expect(job_status.message).to eq nil
          expect(job_status.user_id).to eq user.id
          expect(job_status.main_cc_id).to eq nil
          expect( job_status.status ).to eq "delete_file"
          state = job_status.state_deserialize
          expect( state ).to eq nil
          expect( job_status.state ).to eq nil
          expect( job_status.message ).to eq nil
          expect( job_status.error ).to eq nil
        end
      end

      context "when the file_set isn't the parent's thumbnail" do
        let(:parent) { DataSet.new }

        it "doesn't update the parent's index" do
          expect(file_set).to receive(:reload)
          expect(parent).not_to receive(:update_index)
          expect(::Deepblue::IngestHelper).to receive(:create_derivatives).with( any_args ).and_call_original
          described_class.perform_now(file_set, file.id)
          expect( JobStatus.all.count ).to eq 1
          job_status = JobStatus.all.first
          expect( job_status.job_class ).to eq CreateDerivativesJob.name
          expect( job_status.status ).to eq "delete_file"
          state = job_status.state_deserialize
          expect( state ).to eq nil
          expect( job_status.state ).to eq nil
          expect( job_status.message ).to eq nil
          expect( job_status.error ).to eq nil
        end
      end
    end
  end

  context "with a pdf file" do
    let(:file_set) { create(:file_set) }

    let(:file) do
      Hydra::PCDM::File.new do |f|
        f.content = File.open(File.join(fixture_path, "hyrax/hyrax_test4.pdf"))
        f.original_name = 'test.pdf'
        f.mime_type = 'application/pdf'
      end
    end

    before do
      file_set.original_file = file
      file_set.save!
    end

    it "runs a full text extract" do
      expect(Hydra::Derivatives::PdfDerivatives).to receive(:create)
        .with(/test\.pdf/, outputs: [{ label: :thumbnail,
                                       format: 'jpg',
                                       size: '338x493',
                                       url: String,
                                       layer: 0 }])
      expect(Hydra::Derivatives::FullTextExtract).to receive(:create)
        .with(/test\.pdf/, outputs: [{ url: RDF::URI, container: "extracted_text" }])
      expect(::Deepblue::IngestHelper).to receive(:create_derivatives).with( any_args ).and_call_original
      described_class.perform_now(file_set, file.id)
      expect( JobStatus.all.count ).to eq 1
      job_status = JobStatus.all.first
      expect( job_status.job_class ).to eq CreateDerivativesJob.name
      expect( job_status.status ).to eq "delete_file"
      state = job_status.state_deserialize
      expect( state ).to eq nil
      expect( job_status.state ).to eq nil
      expect( job_status.message ).to eq nil
      expect( job_status.error ).to eq nil
    end
  end

end
