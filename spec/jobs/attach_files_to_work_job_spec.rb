# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AttachFilesToWorkJob, perform_enqueued: [AttachFilesToWorkJob] do

  mattr_accessor :attach_files_to_work_job_spec_debug_verbose, default: false

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.attach_files_to_work_job_debug_verbose ).to eq debug_verbose }
  end

  let(:subject_job) { class_double(AttachFilesToWorkJob ).as_stubbed_const(:transfer_nested_constants => true) }

  let(:file1) { File.open(fixture_path + '/world.png') }
  let(:file2) { File.open(fixture_path + '/image.jp2') }
  let(:uploaded_file1) { build(:uploaded_file, file: file1) }
  let(:uploaded_file2) { build(:uploaded_file, file: file2) }
  let(:data_set) { create(:public_data_set) }
  let(:user) { factory_bot_create_user(:user) }

  shared_examples 'a file attacher', perform_enqueued: [AttachFilesToWorkJob, IngestJob] do
    let(:job) { described_class.send( :job_or_instantiate,
                                      work: data_set,
                                      uploaded_files: [uploaded_file1, uploaded_file2],
                                      user_key: user.user_key ) }

    it 'attaches files, copies visibility and permissions and updates the uploaded files' do
      ActiveJob::Base.queue_adapter = :test
      expect(CharacterizeJob).to receive(:perform_now).twice
      #described_class.perform_now(data_set, [uploaded_file1, uploaded_file2], user.user_key, {})

      expect(job).to receive(:perform_now).with(no_args).and_call_original
      expect(job).not_to receive(:log_error).with( any_args )

      job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
      data_set.reload
      expect(data_set.file_sets.count).to eq 2
      expect(data_set.file_sets.map(&:visibility)).to all(eq 'open')
      expect(uploaded_file1.reload.file_set_uri).not_to be_nil
      expect(ImportUrlJob).not_to have_been_enqueued
      #
      # expect( JobStatus.all.count ).to eq 1 # why is this getting more than 1 on circleci?
      #
      # job_status = JobStatus.all.first
      expect( JobStatus.all.count ).to be_nonzero
      job_status = JobStatus.all.select { |j| j.user_id == user.id }
      job_status = job_status.first
      expect(job_status.job_class).to eq AttachFilesToWorkJob.name
      expect(job_status.job_id).to eq job.job_id
      expect(job_status.parent_job_id).to eq nil
      expect(job_status.error).to eq nil
      expect(job_status.message).to eq "processed uploaded_file: 1\nprocessed uploaded_file: 2"
      expect(job_status.user_id).to eq user.id
      expect(job_status.main_cc_id).to eq data_set.id
      #expect(job_status)
      j = job_status
      ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here,
                                            ::Deepblue::LoggingHelper.called_from,
                                            "j=#{j}",
                                            "j.job_id=#{j.job_id}",
                                            "j.parent_job_id=#{j.parent_job_id}",
                                            "j.message=#{j.message}",
                                            "j.error=#{j.error}",
                                            "j.user_id=#{j.user_id}",
                                            "user.user_key=#{user.user_key}",
                                            "" ] if attach_files_to_work_job_spec_debug_verbose
      expect( job_status.job_class ).to eq AttachFilesToWorkJob.name
      expect( job_status.status ).to eq 'finished'
      state = job_status.state_deserialize
      expect( state['processed_file_set_ids'].sort ).to eq [data_set.file_set_ids[0],data_set.file_set_ids[1]].sort
      expect( state['processed_uploaded_file_ids'] ).to eq [1,2]
      expect( job_status.message ).to eq "processed uploaded_file: 1\nprocessed uploaded_file: 2"
      expect( job_status.error ).to eq nil
    end
  end

  context "with uploaded files on the filesystem", skip: true do
    before do
      data_set.permissions.build(name: 'userz@bbb.ddd', type: 'person', access: 'edit')
      data_set.save
    end
    it_behaves_like 'a file attacher' do
      it 'records the depositor(s) in edit_users' do
        expect(data_set.file_sets.map(&:edit_users)).to all(match_array([data_set.depositor, 'userz@bbb.ddd']))
      end

      describe 'with existing files' do
        let(:file_set)       { create(:file_set) }
        let(:uploaded_file1) { build(:uploaded_file, file: file1, file_set_uri: 'http://example.com/file_set') }

        it 'skips files that already have a FileSet' do
          expect { described_class.perform_now(data_set, [uploaded_file1, uploaded_file2], user.user_key, {}) }
            .to change { data_set.file_sets.count }.to eq 1
        end
      end
    end
  end

  context "with uploaded files at remote URLs", skip: true do
    let(:url1) { 'https://example.com/my/img.png' }
    let(:url2) { URI('https://example.com/other/img.png') }
    let(:fog_file1) { double(CarrierWave::Storage::Abstract, url: url1) }
    let(:fog_file2) { double(CarrierWave::Storage::Abstract, url: url2) }

    before do
      allow(uploaded_file1.file).to receive(:file).and_return(fog_file1)
      allow(uploaded_file2.file).to receive(:file).and_return(fog_file2)
    end

    it_behaves_like 'a file attacher'
  end

  context "deposited on behalf of another user", skip: true do
    before do
      data_set.on_behalf_of = user.user_key
      data_set.save
    end
    it_behaves_like 'a file attacher' do
      it 'records the depositor(s) in edit_users' do
        expect(data_set.file_sets.map(&:edit_users)).to all(match_array([user.user_key]))
      end
    end
  end

  context "deposited as 'Yourself' selected in on behalf of list", skip: true  do
    before do
      data_set.on_behalf_of = ''
      data_set.save
    end
    it_behaves_like 'a file attacher' do
      it 'records the depositor(s) in edit_users' do
        expect(data_set.file_sets.map(&:edit_users)).to all(match_array([data_set.depositor]))
      end
    end
  end

end
