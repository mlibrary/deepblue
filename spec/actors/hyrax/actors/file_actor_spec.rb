require 'rails_helper'

RSpec.describe Hyrax::Actors::FileActor, skip: false do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.file_actor_debug_verbose ).to eq debug_verbose
    end
  end

  include ActionDispatch::TestProcess
  include Hyrax::FactoryHelpers

  let(:user)     { factory_bot_create_user(:user) }
  let(:file_set) { create(:file_set) }
  let(:relation) { :original_file }
  let(:actor)    { described_class.new(file_set, relation, user) }
  let(:fixture)  { fixture_file_upload('/world.png', 'image/png') }
  let(:huf) { Hyrax::UploadedFile.new(user: user, file_set_uri: file_set.uri, file: fixture) }
  let(:io) { JobIoWrapper.new(file_set_id: file_set.id, user: user, uploaded_file: huf) }
  let(:pcdmfile) do
    Hydra::PCDM::File.new.tap do |f|
      f.content = File.open(fixture.path).read
      f.original_name = fixture.original_filename
      f.save!
    end
  end

  let( :job )          { TestJob.send( :job_or_instantiate ) }
  let( :job_id )       { job.job_id }
  let(:job_status_var) { JobStatus.create( job_id: job_id, job_class: job.class ) }
  let(:job_status)     { IngestJobStatus.new( job_status: job_status_var,
                                              verbose: false,
                                              main_cc_id: nil,
                                              user_id: user.id  ) }

  context 'relation' do
    let(:relation) { :remastered }
    let(:file_set) do
      FileSetWithExtras.create!(attributes_for(:file_set)) do |file|
        file.apply_depositor_metadata(user.user_key)
      end
    end

    before do
      class FileSetWithExtras < FileSet
        directly_contains_one :remastered,
                              through: :files,
                              type: ::RDF::URI('http://pcdm.org/use#IntermediateFile'),
                              class_name: 'Hydra::PCDM::File'
      end
    end
    after do
      Object.send(:remove_const, :FileSetWithExtras)
    end
    it 'uses the relation from the actor' do
      expect(CharacterizeJob).to receive(:perform_later).with(file_set,
                                                              String,
                                                              huf.uploader.path,
                                                              current_user: nil,
                                                              parent_job_id: job_id,
                                                              uploaded_file_ids: [] )
      actor.ingest_file(io, job_status: job_status)
      expect(file_set.reload.remastered.mime_type).to eq 'image/png'
    end
  end

  it 'uses the provided mime_type' do
    allow(fixture).to receive(:content_type).and_return('image/gif')
    expect(CharacterizeJob).to receive(:perform_later).with(file_set,
                                                            String,
                                                            huf.uploader.path,
                                                            current_user: nil,
                                                            parent_job_id: job_id,
                                                            uploaded_file_ids: [] )
    actor.ingest_file(io, job_status: job_status)
    expect(file_set.reload.original_file.mime_type).to eq 'image/gif'
  end

  context 'with two existing versions from different users', skip: true do
    let(:fixture2) { fixture_file_upload('/small_file.txt', 'text/plain') }
    let(:huf2) { Hyrax::UploadedFile.new(user: user2, file_set_uri: file_set.uri, file: fixture2) }
    let(:io2) { JobIoWrapper.new(file_set_id: file_set.id, user: user2, uploaded_file: huf2) }
    let(:user2) { factory_bot_create_user(:user) }
    let(:actor2) { described_class.new(file_set, relation, user2) }
    let(:versions) { file_set.reload.original_file.versions }

    before do
      allow(Hydra::Works::CharacterizationService).to receive(:run).with(any_args)
      actor.ingest_file(io, job_status: job_status)
      actor2.ingest_file(io2, job_status: job_status)
    end

    it 'has two versions' do
      expect(versions.all.count).to eq 2
      # the current version
      expect(Hyrax::VersioningService.latest_version_of(file_set.reload.original_file).label).to eq 'version2'
      expect(file_set.original_file.mime_type).to eq 'text/plain'
      expect(file_set.original_file.original_name).to eq 'small_file.txt'
      expect(file_set.original_file.content).to eq fixture2.open.read
      # the user for each version
      expect(Hyrax::VersionCommitter.where(version_id: versions.first.uri).pluck(:committer_login)).to eq [user.user_key]
      expect(Hyrax::VersionCommitter.where(version_id: versions.last.uri).pluck(:committer_login)).to eq [user2.user_key]
    end
  end

  describe '#ingest_file' do
    before do
      expect(Hydra::Works::AddFileToFileSet).to receive(:call).with(file_set,
                                                                    io,
                                                                    relation,
                                                                    update_existing: true,
                                                                    versioning: false)
    end
    it 'when the file is available' do
      allow(file_set).to receive(:save).and_return(true)
      allow(file_set).to receive(relation).and_return(pcdmfile)
      expect(Hyrax::VersioningService).to receive(:create).with(pcdmfile, nil)
      expect(CharacterizeJob).to receive(:perform_later).with(FileSet,
                                                              pcdmfile.id,
                                                              huf.uploader.path,
                                                              current_user: nil,
                                                              parent_job_id: job_id,
                                                              uploaded_file_ids: [] )
      actor.ingest_file(io, job_status: job_status)
    end
    it 'returns false when save fails' do
      allow(file_set).to receive(:save).and_return(false)
      expect(actor.ingest_file(io, job_status: job_status)).to be_falsey
    end
  end

  describe '#revert_to', skip: true do

    let(:revision_id) { 'asdf1234' }

    before do
      allow(pcdmfile).to receive(:restore_version).with(revision_id)
      allow(file_set).to receive(relation).and_return(pcdmfile)
      expect(Hyrax::VersioningService).to receive(:create).with(pcdmfile, user)
      expect(CharacterizeJob).to receive(:perform_later).with(file_set, pcdmfile.id)
    end

    it 'reverts to a previous version of a file' do
      expect(file_set).not_to receive(:remastered)
      expect(actor.relation).to eq(:original_file)
      actor.revert_to(revision_id)
    end

    describe 'for a different relation' do
      let(:relation) { :remastered }

      it 'reverts to a previous version of a file' do
        expect(actor.relation).to eq(:remastered)
        actor.revert_to(revision_id)
      end
      it 'does not rely on the default relation' do
        pending "Hydra::Works::VirusCheck must support other relations: https://github.com/samvera/hyrax/issues/1187"
        expect(actor.relation).to eq(:remastered)
        expect(file_set).not_to receive(:original_file)
        actor.revert_to(revision_id)
      end
    end

  end

end
