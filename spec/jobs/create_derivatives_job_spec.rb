# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreateDerivativesJob, skip: false do

  mattr_accessor :spec_create_derivatives_job_debug_verbose, default: false

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

  describe 'module debug verbose variables' do
    it { expect( described_class.create_derivatives_job_debug_verbose ).to eq false } unless spec_create_derivatives_job_debug_verbose
  end

  # let(:ingest_helper) { class_double(::Deepblue::IngestHelper).as_stubbed_const(:transfer_nested_constants => true) }
  let(:user) { factory_bot_create_user(:user) }

  around do |example|
    ffmpeg_enabled = Hyrax.config.enable_ffmpeg
    Hyrax.config.enable_ffmpeg = true
    example.run
    Hyrax.config.enable_ffmpeg = ffmpeg_enabled
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
        expect { described_class.perform_now(file_set, file.id) }.to change(JobStatus, :count).by(1)
        job_status = JobStatus.all.last
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
      # let(:io)          { JobIoWrapper.new(file_set_id: file_set.id, user: factory_bot_create_user(:user), path: filename) }
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
          expect(:ingest_job_status).to_not eq nil
          expect(job).to receive(:find_or_create_job_status_started).with(parent_job_id: parent_job_id,
                                                                          user_id: user.id,
                                                                          verbose: CreateDerivativesJob.create_derivatives_job_debug_verbose).and_return ingest_job_status
          # expect( job.send( :arguments ) ).to eq []
          expect(File).to receive(:size).with(filepath).at_least(:once).and_return file_size
          # expect(File).to receive(:delete).with(filepath)
          # expect(File).to receive(:exist?).with(filepath).at_least(:once).and_return file_exist
          expect(::Deepblue::DiskUtilitiesHelper).to receive(:file_exists?).with(filepath).at_least(:once).and_return file_exist
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

        it 'updates the index of the parent object', skip: Rails.configuration.hyrax5_spec_skip do
          expect(parent).to receive(:update_index)
          ActiveJob::Base.queue_adapter = :test
          expect {
            job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
          }.to change(JobStatus, :count).by(0)
          expect(job.job_status).to eq ingest_job_status
          job_status_var = JobStatus.all.last
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

      context "when the file_set isn't the parent's thumbnail", skip: Rails.configuration.hyrax5_spec_skip do
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
          # expect(File).to receive(:exist?).with(filepath).at_least(:once).and_return file_exist
          expect(::Deepblue::DiskUtilitiesHelper).to receive(:file_exists?).with(filepath).at_least(:once).and_return file_exist
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
          expect(job).not_to receive(:log_error)
        end

        it "doesn't update the parent's index" do
          expect(parent).not_to receive(:update_index)
          expect {
            job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
          }.to change(JobStatus, :count).by(1)
          job_status = JobStatus.all.last
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

  describe 'with image file' do
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

    RSpec.shared_examples 'it creates derivative given file name' do
      it 'calls create_derivatives and save on a file set' do
        # expect(::Deepblue::IngestHelper).to receive(:file_set_create_derivatives)
        expect(Hydra::Derivatives::ImageDerivatives).to receive(:create)
        expect(file_set).to receive(:reload)
        expect(file_set).to receive(:update_index)
        expect(::Deepblue::IngestHelper).to receive(:create_derivatives).with(any_args).and_call_original
        expect { described_class.perform_now(file_set, file.id) }.to change(JobStatus, :count).by(1)
        job_status = JobStatus.all.last
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

    RSpec.shared_examples 'it creates derivative given parent object' do |thumbnail,dbg_verbose,restart|
      let(:file_set_id) { 'abc12345' }
      let(:filename)    { Rails.root.join('tmp', 'uploads', 'ab', 'c1', '23', '45', 'abc12345', 'picture.png').to_s }
      let(:file_set) do
        FileSet.new(id: file_set_id).tap do |fs|
          allow(fs).to receive(:original_file).and_return file
          allow(fs).to receive(:update_index)
          allow(fs).to receive(:under_embargo?).and_return false
        end
      end
      # let(:io)          { JobIoWrapper.new(file_set_id: file_set.id, user: factory_bot_create_user(:user), path: filename) }
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
      let(:verbose)            { dbg_verbose }
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
        if restart
          expected_calls = 2
        else
          expected_calls = 1
        end
        allow(FileSet).to receive(:find).with(file_set_id).and_return(file_set)
        # expect(::Deepblue::IngestHelper).to receive(:characterize).with(any_args).and_call_original
        allow(file_set).to receive(:parent).and_return(parent)
        # Stub out the actual derivative creation
        allow(Hydra::Derivatives::ImageDerivatives).to receive(:create)
        allow(file_set).to receive(:add_curation_note_admin)
        allow(file_set).to receive(:provenance_create_derivative).with(current_user: current_user,
                                                                       calling_class: Deepblue::IngestHelper.class.name)
        expect(::Deepblue::IngestHelper).not_to receive(:log_error).with(any_args) unless dbg_verbose || spec_create_derivatives_job_debug_verbose

        expect(job_status).to_not eq nil
        expect(JobStatus).to receive(:find_or_create).with(job: job,
                                                           main_cc_id: main_cc_id,
                                                           user_id: user.id).and_return job_status
        expect(job).to receive(:job_status).at_least(:once).and_return ingest_job_status
        expect(:ingest_job_status).to_not eq nil
        expect(job).to receive(:find_or_create_job_status_started).with(parent_job_id: parent_job_id,
                                                                        user_id: user.id,
                                                                        verbose: dbg_verbose).
                                                        at_least(expected_calls).times.and_return ingest_job_status
        expect(File).to receive(:size).with(filepath).at_least(:once).and_return file_size
        expect(File).to receive(:delete).with(filepath)
        # expect(File).to receive(:exist?).with(filepath).at_least(:once).and_return file_exist
        expect(::Deepblue::DiskUtilitiesHelper).to receive(:file_exists?).with(filepath).at_least(:once).and_return file_exist
        call_count = 0
        expect(Hyrax::WorkingDirectory).to receive(:find_or_retrieve).with( repository_file_id,
                                                                            file_set.id,
                                                                            filepath ).at_least(expected_calls).times do
          if restart
            if 0 == call_count
              call_count += 1
              raise RuntimeError, "Hyrax::WorkingDirectory: fail for restart"
            else
              filepath
            end
          else
            filepath
          end
        end

        expect(::Deepblue::IngestHelper).to receive(:create_derivatives).at_least(expected_calls).times do |args|
          expect(args[0]).to eq anything
          expect(args[1]).to eq filepath
          expect(args[:current_user]).to eq current_user
          expect(args[:delete_input_file]).to eq delete_input_file
          expect(args[:job_status]).to eq anything
          expect(args[:uploaded_file_ids]).to eq uploaded_file_ids
        end.and_call_original
        expect(job).to receive(:perform_now).with(no_args).at_least(expected_calls).times.and_call_original
        expect(file_set).to receive(:reload)
        expect(ingest_job_status).to receive(:did_create_derivatives?).at_least(expected_calls).times.with(no_args).and_call_original
        expect(ingest_job_status).to receive(:did_create_derivatives!).with(no_args).and_call_original
        if restart
          expect(job).to receive(:log_error) do |arg|
            # expect(args[0].is_a? RuntimeError).to eq true
            # expect(args[0].message).to eq "Hyrax::WorkingDirectory: fail for restart"
            expect(arg).to eq "CreateDerivativesJob.perform(#{file_set},#{repository_file_id},#{filepath}) RuntimeError: Hyrax::WorkingDirectory: fail for restart"
          end
        else
          expect(job).not_to receive(:log_error)
        end
        expect(::Deepblue::IngestHelper).not_to receive(:log_error).with( any_args )
        if dbg_verbose
          expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once)
        else
          expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug)
        end
      end

      it 'calls create_derivatives and save on a file set' do
        save_debug_verbose = described_class.create_derivatives_job_debug_verbose
        described_class.create_derivatives_job_debug_verbose = dbg_verbose
        # expect(::Deepblue::IngestHelper).to receive(:file_set_create_derivatives)
        expect(file_set).to receive(:create_derivatives)
        if thumbnail
          expect(parent).to receive(:update_index)
        else
          expect(parent).not_to receive(:update_index)
        end
        ActiveJob::Base.queue_adapter = :test
        expect {
          job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
        }.to change(JobStatus, :count).by(0)
        expect(job.job_status).to eq ingest_job_status
        job_status_var = JobStatus.all.last
        expect(job_status_var).to eq ingest_job_status.job_status
        expect(job_status_var.job_class).to eq CreateDerivativesJob.name
        expect(job_status_var.job_id).to eq job.job_id
        expect(job_status_var.parent_job_id).to eq parent_job_id
        expect(job_status_var.error).to eq nil
        lines_expected = []
        lines_expected << 'did? finished_create_derivatives returning false because current status is blank'
        lines_expected << 'status changed to: finished_characterize'
        lines_expected << 'status changed to: finished_create_derivatives'
        lines_expected << 'did? delete_file returning false because current status is finished_create_derivatives'
        lines_expected << 'status changed to: delete_file'
        if dbg_verbose
          if restart
            expect(job_status_var.message).to eq 'did? finished_create_derivatives returning false because current status is blank'
          else
            lines = job_status_var.message
            lines = "" if lines.blank?
            lines = lines.split("\n")
            expect(lines).to eq lines_expected
          end
        else
          expect(job_status_var.message).to eq nil unless spec_create_derivatives_job_debug_verbose
        end
        expect(job_status_var.user_id).to eq user.id
        expect(job_status_var.main_cc_id).to eq nil
        if restart
          expect(job_status_var.status).to eq nil
        else
          expect(job_status_var.status).to eq "delete_file"
        end
        state = job_status_var.state_deserialize
        expect( state ).to eq nil
        expect( job_status_var.state ).to eq nil
        if dbg_verbose
          if restart
            expect(job_status_var.message).to eq 'did? finished_create_derivatives returning false because current status is blank'
          else
            lines = job_status_var.message
            lines = "" if lines.blank?
            lines = lines.split("\n")
            expect(lines).to eq lines_expected
          end
        else
          expect( job_status_var.message ).to eq nil unless spec_create_derivatives_job_debug_verbose
        end
        expect( job_status_var.error ).to eq nil
        if restart
          expect {
            job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
          }.to change(JobStatus, :count).by(0)
          expect(job.job_status).to eq ingest_job_status
          job_status_var = JobStatus.all.last
          expect(job_status_var).to eq ingest_job_status.job_status
          expect(job_status_var.job_class).to eq CreateDerivativesJob.name
          expect(job_status_var.job_id).to eq job.job_id
          expect(job_status_var.parent_job_id).to eq parent_job_id
          expect(job_status_var.error).to eq nil
          lines_expected = []
          lines_expected << 'did? finished_create_derivatives returning false because current status is blank'
          lines_expected << 'did? finished_create_derivatives returning false because current status is blank'
          lines_expected << 'status changed to: finished_characterize'
          lines_expected << 'status changed to: finished_create_derivatives'
          lines_expected << 'did? delete_file returning false because current status is finished_create_derivatives'
          lines_expected << 'status changed to: delete_file'
          if dbg_verbose
            lines = job_status_var.message
            lines = "" if lines.blank?
            lines = lines.split("\n")
            expect(lines).to eq lines_expected
          else
            expect(job_status_var.message).to eq nil unless spec_create_derivatives_job_debug_verbose
          end
          expect(job_status_var.user_id).to eq user.id
          expect(job_status_var.main_cc_id).to eq nil
          expect(job_status_var.status).to eq "delete_file"
          state = job_status_var.state_deserialize
          expect( state ).to eq nil
          expect( job_status_var.state ).to eq nil
          if dbg_verbose
            lines = job_status_var.message
            lines = "" if lines.blank?
            lines = lines.split("\n")
            expect(lines).to eq lines_expected
          else
            expect( job_status_var.message ).to eq nil unless spec_create_derivatives_job_debug_verbose
          end
          expect( job_status_var.error ).to eq nil
        end
        described_class.create_derivatives_job_debug_verbose = save_debug_verbose
      end
    end

    context "with a file name", skip: false do
      it_behaves_like 'it creates derivative given file name'
    end

    describe 'with a parent object' do

      context 'when the file_set is the thumbnail for parent', skip: false do
        let(:parent) { DataSet.new(thumbnail_id: id) }
        thumbnail = true
        restart = false
        it it_behaves_like 'it creates derivative given parent object', thumbnail, false, restart
        it it_behaves_like 'it creates derivative given parent object', thumbnail, true, restart
      end

      context "when the file_set isn't the parent's thumbnail", skip: false do
        let(:parent) { DataSet.new }
        thumbnail = false
        restart = false
        it it_behaves_like 'it creates derivative given parent object', thumbnail, false, restart
        it it_behaves_like 'it creates derivative given parent object', thumbnail, true, restart
      end

      context "when the file_set isn't the parent's thumbnail and restart", skip: false do
        let(:parent) { DataSet.new }
        thumbnail = false
        restart = true
        it it_behaves_like 'it creates derivative given parent object', thumbnail, false, restart
        it it_behaves_like 'it creates derivative given parent object', thumbnail, true, restart
      end

    end

  end

  context "with a pdf file", skip: true do
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
      expect { described_class.perform_now(file_set, file.id) }.to change(JobStatus, :count).by(1)
      job_status = JobStatus.all.last
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
