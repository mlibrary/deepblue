# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreateDerivativesJob, skip: false do

  mattr_accessor :spec_create_derivatives_job_debug_verbose
  @@spec_create_derivatives_job_debug_verbose = false

  before :all do
    if spec_create_derivatives_job_debug_verbose
      ::Deepblue::LoggingHelper.echo_to_puts = true
      ::Deepblue::IngestHelper.ingest_helper_debug_verbose = true
      CreateDerivativesJob.create_derivatives_job_debug_verbose = true
    end
  end

  after :all do
    if spec_create_derivatives_job_debug_verbose
      ::Deepblue::LoggingHelper.echo_to_puts = false
      ::Deepblue::IngestHelper.ingest_helper_debug_verbose = false
      CreateDerivativesJob.create_derivatives_job_debug_verbose = false
    end
  end

  # let(:ingest_helper) { class_double(::Deepblue::IngestHelper).as_stubbed_const(:transfer_nested_constants => true) }
  let(:user) { create(:user) }

  around do |example|
    ffmpeg_enabled = Hyrax.config.enable_ffmpeg
    Hyrax.config.enable_ffmpeg = true
    example.run
    Hyrax.config.enable_ffmpeg = ffmpeg_enabled
  end

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.create_derivatives_job_debug_verbose ).to eq( false ) unless spec_create_derivatives_job_debug_verbose
    end
  end

  context "with an audio file", skip: false do
    # ignore the fact that file has a .png name, the mimetype is audio
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
      allow(file_set).to receive(:add_curation_note_admin)
    end

    context "with a file name", skip: false do
      it 'calls create_derivatives and save on a file set' do
        expect(Hydra::Derivatives::AudioDerivatives).to receive(:create)
        expect(file_set).to receive(:reload)
        expect(file_set).to receive(:update_index)
        expect(::Deepblue::IngestHelper).to receive(:create_derivatives).with(any_args).and_call_original
        described_class.perform_now(file_set, file.id)
        expect(JobStatus.all.count).to eq 1
        job_status = JobStatus.all.first
        expect(job_status.job_class).to eq CreateDerivativesJob.name
        expect(job_status.status).to eq "delete_file"
        state = job_status.state_deserialize
        expect(state).to eq nil
        expect(job_status.state).to eq nil
        expect(job_status.message).to eq nil unless spec_create_derivatives_job_debug_verbose
        puts "job_status.error='#{job_status.error}'" if spec_create_derivatives_job_debug_verbose
        expect(job_status.error).to eq nil
      end
    end

    describe 'with a parent object' do
      let(:file_set_id) { 'abc12345' }
      let(:filename)    { Rails.root.join('tmp', 'uploads', 'ab', 'c1', '23', '45', 'abc12345', 'picture.png').to_s }
      let(:file_set) do
        FileSet.new(id: file_set_id).tap do |fs|
          allow(fs).to receive(:original_file).and_return file
          allow(fs).to receive(:update_index)
          allow(fs).to receive(:under_embargo?).and_return false
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

      let(:repository_file_id) { nil }
      let(:filepath)           { filename }
      let(:current_user)       { user }
      let(:delete_input_file)  { true }
      let(:parent_job_id)      { nil }
      let(:uploaded_file_ids)  { []  }
      let(:file_exist)         { true }
      let(:file_size)          { 111 }
      let(:main_cc_id)         { nil }
      let(:verbose)            { false }

      before do
        allow(FileSet).to receive(:find).with(file_set_id).and_return(file_set)
        # expect(::Deepblue::IngestHelper).to receive(:characterize).with(any_args).and_call_original
        allow(file_set).to receive(:parent).and_return(parent)
        # Stub out the actual derivative creation
        allow(file_set).to receive(:create_derivatives)
        allow(file_set).to receive(:add_curation_note_admin)
        allow(file_set).to receive(:provenance_create_derivative).with(current_user: current_user,
                                                                       calling_class: Deepblue::IngestHelper.class.name)
        expect(::Deepblue::IngestHelper).not_to receive(:log_error).with(any_args) unless spec_create_derivatives_job_debug_verbose
      end

      context 'when the file_set is the thumbnail of the parent' do
        let(:parent) { DataSet.new(thumbnail_id: id) }
        let(:job)    { CreateDerivativesJob.send( :job_or_instantiate,
                                                  file_set,
                                                  repository_file_id,
                                                  filepath,
                                                  current_user: current_user,
                                                  delete_input_file: delete_input_file,
                                                  parent_job_id: parent_job_id,
                                                  uploaded_file_ids: uploaded_file_ids ) }
        let(:job_status) { JobStatus.find_or_create(job: job,
                                             status: nil,
                                             message: nil,
                                             error: nil,
                                             parent_job_id: parent_job_id,
                                             main_cc_id: main_cc_id,
                                             user_id: user.id) }
        let(:ingest_job_status) do
          ijb = IngestJobStatus.new(job: job, verbose: verbose, main_cc_id: main_cc_id, user_id: user.id)
          ijb.save!
          ijb
        end

        before do
          expect(job_status).to_not eq nil
          expect(JobStatus).to receive(:find_or_create).with(job: job,
                                                             main_cc_id: main_cc_id,
                                                             user_id: user.id).and_return job_status
          expect(job).to receive(:job_status).at_least(:once).and_return ingest_job_status
          expect(JobStatus.all.count).to eq 1
          expect(:ingest_job_status).to_not eq nil
          expect(job).to receive(:find_or_create_job_status_started).with(parent_job_id: parent_job_id,
                                                                          user_id: user.id,
                                                                          verbose: CreateDerivativesJob.create_derivatives_job_debug_verbose).and_return ingest_job_status
          # expect( job.send( :arguments ) ).to eq []
          expect(File).to receive(:size).with(filepath).at_least(:once).and_return file_size
          expect(File).to receive(:delete).with(filepath)
          expect(File).to receive(:exist?).with(filepath).at_least(:once).and_return file_exist
          expect(Hyrax::WorkingDirectory).to receive(:find_or_retrieve).with( repository_file_id,
                                                                              file_set.id,
                                                                              filepath ).and_return filepath
          expect(::Deepblue::IngestHelper).to receive(:create_derivatives) do |args|
            expect(args[0]).to eq anything
            expect(args[1]).to eq filepath
            expect(args[:current_user]).to eq current_user
            expect(args[:delete_input_file]).to eq delete_input_file
            expect(args[:job_status]).to eq anything
            expect(args[:uploaded_file_ids]).to eq uploaded_file_ids
          end.and_call_original
          expect(job).to receive(:perform_now).with(no_args).and_call_original
          expect(file_set).to receive(:reload)
          expect(ingest_job_status).to receive(:did_create_derivatives?).with(no_args).and_call_original
          expect(ingest_job_status).to receive(:did_create_derivatives!).with(no_args).and_call_original
          expect(job).not_to receive(:log_error)
        end

        it 'updates the index of the parent object' do
          expect(parent).to receive(:update_index)
          ActiveJob::Base.queue_adapter = :test
          job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
          expect(job.job_status).to eq ingest_job_status
          ### expect( job.send( :arguments ) ).to eq []
          expect(JobStatus.all.count).to eq 1
          job_status_var = JobStatus.all.first
          expect(job_status_var).to eq ingest_job_status.job_status
          expect(job_status_var.job_class).to eq CreateDerivativesJob.name
          expect(job_status_var.job_id).to eq job.job_id
          expect(job_status_var.parent_job_id).to eq parent_job_id
          expect(job_status_var.error).to eq nil
          expect(job_status_var.message).to eq nil unless spec_create_derivatives_job_debug_verbose
          expect(job_status_var.user_id).to eq user.id
          expect(job_status_var.main_cc_id).to eq nil
          expect(job_status_var.status).to eq "delete_file"
          state = job_status_var.state_deserialize
          expect( state ).to eq nil
          expect( job_status_var.state ).to eq nil
          expect( job_status_var.message ).to eq nil unless spec_create_derivatives_job_debug_verbose
          expect( job_status_var.error ).to eq nil
        end
      end

      context "when the file_set isn't the parent's thumbnail", skip: false do
        let(:parent) { DataSet.new }
        let(:parent_job_id) { nil }
        let(:job)    { CreateDerivativesJob.send( :job_or_instantiate,
                                                  file_set,
                                                  repository_file_id,
                                                  filepath,
                                                  current_user: current_user,
                                                  delete_input_file: delete_input_file,
                                                  parent_job_id: parent_job_id,
                                                  uploaded_file_ids: uploaded_file_ids ) }

        before do
          expect(::Deepblue::IngestHelper).not_to receive(:log_error).with( any_args )
          expect(File).to receive(:size).with(filepath).at_least(:once).and_return file_size
          expect(File).to receive(:delete).with(filepath)
          expect(File).to receive(:exist?).with(filepath).at_least(:once).and_return file_exist
          expect(Hyrax::WorkingDirectory).to receive(:find_or_retrieve).with( repository_file_id,
                                                                              file_set.id,
                                                                              filepath ).and_call_original
          expect(::Deepblue::IngestHelper).to receive(:create_derivatives) do |args|
            expect(args[0]).to eq anything
            expect(args[1]).to eq filepath
            expect(args[:current_user]).to eq current_user
            expect(args[:delete_input_file]).to eq delete_input_file
            expect(args[:job_status]).to eq anything
            expect(args[:uploaded_file_ids]).to eq uploaded_file_ids
          end.and_call_original
          expect(job).to receive(:perform_now).with(no_args).and_call_original
          expect(job).to receive(:find_or_create_job_status_started).with(parent_job_id: parent_job_id,
                                                                          user_id: user.id,
                                                                          verbose: CreateDerivativesJob.create_derivatives_job_debug_verbose).and_call_original
          expect(file_set).to receive(:reload)
          expect(JobStatus.all.count).to eq 0
          expect(job).not_to receive(:log_error)
        end

        it "doesn't update the parent's index" do
          expect(parent).not_to receive(:update_index)
          job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
          expect( JobStatus.all.count ).to eq 1
          job_status = JobStatus.all.first
          expect(job_status.job_class).to eq CreateDerivativesJob.name
          expect(job_status.job_id).to eq job.job_id
          expect(job_status.parent_job_id).to eq parent_job_id
          expect(job_status.error).to eq nil
          expect(job_status.message).to eq nil unless spec_create_derivatives_job_debug_verbose
          expect(job_status.user_id).to eq user.id
          expect(job_status.main_cc_id).to eq nil
          expect(job_status.status).to eq "delete_file"
          state = job_status.state_deserialize
          expect( state ).to eq nil
          expect( job_status.state ).to eq nil
          expect( job_status.message ).to eq nil unless spec_create_derivatives_job_debug_verbose
          expect( job_status.error ).to eq nil
        end
      end


    end

  end

  context "with an image file" do
    # ignore the fact that file has a .png name, the mimetype is audio
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
      allow(file_set).to receive(:mime_type).and_return('image/png')
      allow(file_set).to receive(:add_curation_note_admin)
    end

    context "with a file name", skip: false do
      it 'calls create_derivatives and save on a file set' do
        # expect(::Deepblue::IngestHelper).to receive(:file_set_create_derivatives)
        expect(Hydra::Derivatives::ImageDerivatives).to receive(:create)
        expect(file_set).to receive(:reload)
        expect(file_set).to receive(:update_index)
        expect(::Deepblue::IngestHelper).to receive(:create_derivatives).with(any_args).and_call_original
        described_class.perform_now(file_set, file.id)
        expect(JobStatus.all.count).to eq 1
        job_status = JobStatus.all.first
        expect(job_status.job_class).to eq CreateDerivativesJob.name
        expect(job_status.status).to eq "delete_file"
        state = job_status.state_deserialize
        expect(state).to eq nil
        expect(job_status.state).to eq nil
        expect(job_status.message).to eq nil unless spec_create_derivatives_job_debug_verbose
        puts "job_status.error='#{job_status.error}'" if spec_create_derivatives_job_debug_verbose
        expect(job_status.error).to eq nil
      end
    end

    describe 'with a parent object' do
      let(:file_set_id) { 'abc12345' }
      let(:filename)    { Rails.root.join('tmp', 'uploads', 'ab', 'c1', '23', '45', 'abc12345', 'picture.png').to_s }
      let(:file_set) do
        FileSet.new(id: file_set_id).tap do |fs|
          allow(fs).to receive(:original_file).and_return file
          allow(fs).to receive(:update_index)
          allow(fs).to receive(:under_embargo?).and_return false
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

      let(:repository_file_id) { nil }
      let(:filepath)           { filename }
      let(:current_user)       { user }
      let(:delete_input_file)  { true }
      let(:parent_job_id)      { nil }
      let(:uploaded_file_ids)  { []  }
      let(:file_exist)         { true }
      let(:file_size)          { 111 }
      let(:main_cc_id)         { nil }
      let(:verbose)            { false }

      before do
        allow(FileSet).to receive(:find).with(file_set_id).and_return(file_set)
        # expect(::Deepblue::IngestHelper).to receive(:characterize).with(any_args).and_call_original
        allow(file_set).to receive(:parent).and_return(parent)
        # Stub out the actual derivative creation
        allow(Hydra::Derivatives::ImageDerivatives).to receive(:create)
        allow(file_set).to receive(:add_curation_note_admin)
        allow(file_set).to receive(:provenance_create_derivative).with(current_user: current_user,
                                                                       calling_class: Deepblue::IngestHelper.class.name)
        expect(::Deepblue::IngestHelper).not_to receive(:log_error).with(any_args) unless spec_create_derivatives_job_debug_verbose
      end

      context 'when the file_set is the thumbnail of the parent', skip: false do
        let(:parent) { DataSet.new(thumbnail_id: id) }
        let(:job)    { CreateDerivativesJob.send( :job_or_instantiate,
                                                  file_set,
                                                  repository_file_id,
                                                  filepath,
                                                  current_user: current_user,
                                                  delete_input_file: delete_input_file,
                                                  parent_job_id: parent_job_id,
                                                  uploaded_file_ids: uploaded_file_ids ) }
        let(:job_status) { JobStatus.find_or_create(job: job,
                                                    status: nil,
                                                    message: nil,
                                                    error: nil,
                                                    parent_job_id: parent_job_id,
                                                    main_cc_id: main_cc_id,
                                                    user_id: user.id) }
        let(:ingest_job_status) do
          ijb = IngestJobStatus.new(job: job, verbose: verbose, main_cc_id: main_cc_id, user_id: user.id)
          ijb.save!
          ijb
        end

        before do
          expect(job_status).to_not eq nil
          expect(JobStatus).to receive(:find_or_create).with(job: job,
                                                             main_cc_id: main_cc_id,
                                                             user_id: user.id).and_return job_status
          expect(job).to receive(:job_status).at_least(:once).and_return ingest_job_status
          expect(JobStatus.all.count).to eq 1
          expect(:ingest_job_status).to_not eq nil
          expect(job).to receive(:find_or_create_job_status_started).with(parent_job_id: parent_job_id,
                                                                          user_id: user.id,
                                                                          verbose: CreateDerivativesJob.create_derivatives_job_debug_verbose).and_return ingest_job_status
          # expect( job.send( :arguments ) ).to eq []
          expect(File).to receive(:size).with(filepath).at_least(:once).and_return file_size
          expect(File).to receive(:delete).with(filepath)
          expect(File).to receive(:exist?).with(filepath).at_least(:once).and_return file_exist
          expect(Hyrax::WorkingDirectory).to receive(:find_or_retrieve).with( repository_file_id,
                                                                              file_set.id,
                                                                              filepath ).and_return filepath
          expect(::Deepblue::IngestHelper).to receive(:create_derivatives) do |args|
            expect(args[0]).to eq anything
            expect(args[1]).to eq filepath
            expect(args[:current_user]).to eq current_user
            expect(args[:delete_input_file]).to eq delete_input_file
            expect(args[:job_status]).to eq anything
            expect(args[:uploaded_file_ids]).to eq uploaded_file_ids
          end.and_call_original
          expect(job).to receive(:perform_now).with(no_args).and_call_original
          expect(file_set).to receive(:reload)
          expect(ingest_job_status).to receive(:did_create_derivatives?).with(no_args).and_call_original
          expect(ingest_job_status).to receive(:did_create_derivatives!).with(no_args).and_call_original
          expect(job).not_to receive(:log_error)
        end

        it 'updates the index of the parent object' do
          expect(::Deepblue::IngestHelper).to receive(:file_set_create_derivatives)
          expect(parent).to receive(:update_index)
          ActiveJob::Base.queue_adapter = :test
          job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
          expect(job.job_status).to eq ingest_job_status
          ### expect( job.send( :arguments ) ).to eq []
          expect(JobStatus.all.count).to eq 1
          job_status_var = JobStatus.all.first
          expect(job_status_var).to eq ingest_job_status.job_status
          expect(job_status_var.job_class).to eq CreateDerivativesJob.name
          expect(job_status_var.job_id).to eq job.job_id
          expect(job_status_var.parent_job_id).to eq parent_job_id
          expect(job_status_var.error).to eq nil
          expect(job_status_var.message).to eq nil unless spec_create_derivatives_job_debug_verbose
          expect(job_status_var.user_id).to eq user.id
          expect(job_status_var.main_cc_id).to eq nil
          expect(job_status_var.status).to eq "delete_file"
          state = job_status_var.state_deserialize
          expect( state ).to eq nil
          expect( job_status_var.state ).to eq nil
          expect( job_status_var.message ).to eq nil unless spec_create_derivatives_job_debug_verbose
          expect( job_status_var.error ).to eq nil
        end
      end

      context "when the file_set isn't the parent's thumbnail", skip: false do
        let(:parent) { DataSet.new }
        let(:parent_job_id) { nil }
        let(:job)    { CreateDerivativesJob.send( :job_or_instantiate,
                                                  file_set,
                                                  repository_file_id,
                                                  filepath,
                                                  current_user: current_user,
                                                  delete_input_file: delete_input_file,
                                                  parent_job_id: parent_job_id,
                                                  uploaded_file_ids: uploaded_file_ids ) }

        before do
          expect(::Deepblue::IngestHelper).not_to receive(:log_error).with( any_args )
          expect(File).to receive(:size).with(filepath).at_least(:once).and_return file_size
          expect(File).to receive(:delete).with(filepath)
          expect(File).to receive(:exist?).with(filepath).at_least(:once).and_return file_exist
          expect(Hyrax::WorkingDirectory).to receive(:find_or_retrieve).with( repository_file_id,
                                                                              file_set.id,
                                                                              filepath ).and_call_original
          expect(::Deepblue::IngestHelper).to receive(:create_derivatives) do |args|
            expect(args[0]).to eq anything
            expect(args[1]).to eq filepath
            expect(args[:current_user]).to eq current_user
            expect(args[:delete_input_file]).to eq delete_input_file
            expect(args[:job_status]).to eq anything
            expect(args[:uploaded_file_ids]).to eq uploaded_file_ids
          end.and_call_original
          expect(job).to receive(:perform_now).with(no_args).and_call_original
          expect(job).to receive(:find_or_create_job_status_started).with(parent_job_id: parent_job_id,
                                                                          user_id: user.id,
                                                                          verbose: CreateDerivativesJob.create_derivatives_job_debug_verbose).and_call_original
          expect(file_set).to receive(:reload)
          expect(JobStatus.all.count).to eq 0
          expect(job).not_to receive(:log_error)
        end

        it "doesn't update the parent's index" do
          # expect(::Deepblue::IngestHelper).to receive(:file_set_create_derivatives)
          expect(file_set).to receive(:create_derivatives)
          expect(parent).not_to receive(:update_index)
          job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
          expect( JobStatus.all.count ).to eq 1
          job_status = JobStatus.all.first
          expect(job_status.job_class).to eq CreateDerivativesJob.name
          expect(job_status.job_id).to eq job.job_id
          expect(job_status.parent_job_id).to eq parent_job_id
          expect(job_status.error).to eq nil
          expect(job_status.message).to eq nil unless spec_create_derivatives_job_debug_verbose
          expect(job_status.user_id).to eq user.id
          expect(job_status.main_cc_id).to eq nil
          expect(job_status.status).to eq "delete_file"
          state = job_status.state_deserialize
          expect( state ).to eq nil
          expect( job_status.state ).to eq nil
          expect( job_status.message ).to eq nil unless spec_create_derivatives_job_debug_verbose
          expect( job_status.error ).to eq nil
        end
      end


    end

  end

  context "with a pdf file", skip: false do
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
