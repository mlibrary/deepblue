# frozen_string_literal: true

require 'rails_helper'

require 'rails_helper'

RSpec.describe Deepblue::IngestHelper, type: :helper do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.ingest_helper_debug_verbose ).to eq debug_verbose
    end
  end

  it "#after_create_derivative" do
    skip "the test code goes here"
  end

  it "#characterize" do
    skip "the test code goes here"
  end

  it "#create_derivatives" do
    skip "the test code goes here"
  end

  it "#create_derivatives_duration" do
    skip "the test code goes here"
  end

  it "#current_user" do
    skip "the test code goes here"
  end

  it "#delete_file" do
    skip "the test code goes here"
  end

  it "#file_set_actor_create_content" do
    skip "the test code goes here"
  end

  it "#file_too_big" do
    skip "the test code goes here"
  end

  it "#ingest" do
    skip "the test code goes here"
  end

  it "#label_for" do
    skip "the test code goes here"
  end

  it "#log_error" do
    skip "the test code goes here"
  end

  it "#related_file" do
    skip "the test code goes here"
  end

  it "#perform_create_derivatives_job" do
    skip "the test code goes here"
  end

  it "#update_total_file_size" do
    skip "the test code goes here"
  end

  it "#virus_scan" do
    skip "the test code goes here"
  end

  it "#compose_e_msg" do
    skip "the test code goes here"
  end

  describe "call create derivative fail and recall" do
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

    let(:user) { create(:user) }
    let(:repository_file_id) { nil }
    let(:filepath)           { nil }
    let(:current_user)       { user }
    let(:delete_input_file)  { true }
    let(:uploaded_file_ids)  { []  }

    context "for failure and restart", skip: false do

      let(:parent)            { DataSet.new }
      let(:parent_job_class)  { "TheParentJobClass" }
      let(:parent_job_id)     { "pjid0001" }
      #let(:job_status)        { JobStatus.create( job_id: parent_job_id, job_class: parent_job_class ) }
      let(:job_status)        do
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "JobStatus.all.count=#{JobStatus.all.count}" ]
        js = JobStatus.new( job_id: parent_job_id, job_class: parent_job_class )
        js.status = JobStatus::STARTED
        js.user_id = user.id
        js.save
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "JobStatus.all.count=#{JobStatus.all.count}" ]
        js
      end
      let(:count1) { JobStatus.all.count }
      let(:parent_job_status) do
        # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
        #                                        ::Deepblue::LoggingHelper.called_from,
        #                                        "JobStatus.all.count=#{JobStatus.all.count}" ]
        IngestJobStatus.new( job_status: job_status, verbose: false, main_cc_id: nil, user_id: user.id  )
      end

      before do
        allow(FileSet).to receive(:find).with(file_set_id).and_return(file_set)
        expect(Hyrax::WorkingDirectory).to receive(:find_or_retrieve).with(any_args).and_return filepath
        allow(described_class).to receive(:file_too_big).and_return false
        allow(file_set).to receive(:parent).and_return(parent)
        # Stub out the actual derivative creation
        allow(file_set).to receive(:create_derivatives)
        # expect( JobStatus.all.count ).to eq 1
        expect(::Deepblue::IngestHelper).not_to receive(:log_error).with( any_args )
        expect(file_set).to receive(:reload)
        expect(::Deepblue::IngestHelper).to receive(:create_derivatives) do |args|
          expect(args[0]).to eq anything
          expect(args[1]).to eq filepath
          expect(args[:current_user]).to eq current_user
          expect(args[:delete_input_file]).to eq delete_input_file
          expect(args[:job_status]).to eq anything
          expect(args[:uploaded_file_ids]).to eq uploaded_file_ids
        end.and_call_original
        expect(parent_job_status).to receive(:did_create_derivatives?).at_least(:once).and_call_original
      end

      it 'updates the index of the parent object' do
        # expect(parent).to receive(:update_index)
        ActiveJob::Base.queue_adapter = :test
        described_class.create_derivatives( file_set,
                                            repository_file_id,
                                            filepath,
                                            current_user: user,
                                            delete_input_file: true,
                                            job_status: parent_job_status,
                                            uploaded_file_ids: uploaded_file_ids )
        expect(JobStatus.all.count).to eq 1
        job_status = JobStatus.all.first
        expect(job_status.job_class).to eq parent_job_class
        expect(job_status.job_id).to eq parent_job_id
        expect(job_status.parent_job_id).to eq nil
        expect(job_status.error).to eq nil
        expect(job_status.message).to eq nil
        expect(job_status.user_id).to eq user.id
        expect(job_status.main_cc_id).to eq nil
        expect(job_status.status).to eq "delete_file"
        state = job_status.state_deserialize
        expect( state ).to eq nil
        expect( job_status.state ).to eq nil
        expect( job_status.message ).to eq nil
        expect( job_status.error ).to eq nil
      end

    end

  end

end
