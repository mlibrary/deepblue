# frozen_string_literal: true

require 'rails_helper'

require 'rails_helper'

RSpec.describe ::Deepblue::IngestHelper, type: :helper do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.ingest_helper_debug_verbose ).to eq debug_verbose
      expect( described_class.ingest_helper_debug_verbose_puts ).to eq false
    end
  end

  describe 'all', skip: false do
    RSpec.shared_examples 'shared ::Deepblue::IngestHelper' do |dbg_verbose|
      subject { described_class }
      before do
        described_class.ingest_helper_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose
      end
      after do
        described_class.ingest_helper_debug_verbose = debug_verbose
      end
      context do
        let(:file_set_id)   { 'abc12345' }
        let(:filename)      { Rails.root.join('tmp', 'uploads', 'ab', 'c1', '23', '45', 'abc12345', 'picture.png').to_s }

        it "#after_create_derivative" do
          ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
          skip "the test code goes here"
        end

        it "#characterize" do
          ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
          skip "the test code goes here"
        end

        describe "#create_derivatives" do
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

          let(:user)               { create(:user) }
          let(:repository_file_id) { nil }
          let(:filepath)           { nil }
          let(:current_user)       { user }
          let(:delete_input_file)  { true }
          let(:uploaded_file_ids)  { []  }

          context "for failure and restart", skip: false do

            let(:parent)            { DataSet.new }
            let(:parent_job_class)  { "TheParentJobClass" }
            let(:parent_job_id)     { "pjid0001" }
            let(:job_status)        do
              # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
              #                                        ::Deepblue::LoggingHelper.called_from,
              #                                        "JobStatus.all.count=#{JobStatus.all.count}" ]
              js = JobStatus.new( job_id: parent_job_id, job_class: parent_job_class )
              js.status = JobStatus::STARTED
              js.user_id = user.id
              js.save
              # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
              #                                        ::Deepblue::LoggingHelper.called_from,
              #                                        "JobStatus.all.count=#{JobStatus.all.count}" ]
              js
            end
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
              count = JobStatus.all.count
              expect {
                described_class.create_derivatives( file_set,
                                                    repository_file_id,
                                                    filepath,
                                                    current_user: user,
                                                    delete_input_file: true,
                                                    job_status: parent_job_status,
                                                    uploaded_file_ids: uploaded_file_ids ) }.to change(JobStatus, :count).by(0)
              job_status = JobStatus.all.last
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

        describe "#create_derivatives_duration" do
          let(:file_set) do
            FileSet.new(id: file_set_id).tap do |fs|
              allow(fs).to receive(:original_file).and_return(file)
            end
          end
          let(:file) do
            Hydra::PCDM::File.new.tap do |f|
              f.content = 'foo'
              f.original_name = 'picture.png'
              f.save!
              allow(f).to receive(:save!)
            end
          end

          context 'it returns' do

            it 'the correct value' do
              expect(described_class.create_derivatives_duration file_set).to eq 0
              ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
            end

          end

        end

        it "#current_user" do
          ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
          skip "the test code goes here"
        end

        it "#delete_file" do
          ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
          skip "the test code goes here"
        end

        describe '#derivative_excluded_ext_set?' do
          context 'excluded extension' do
            let(:file_ext) { '.xslx' }

            before do
              allow(  Rails.configuration ).to receive(:derivative_excluded_ext_set).and_return( { file_ext => true }.freeze )
            end

            it 'returns true' do
              expect(described_class.derivative_excluded_ext_set? file_ext).to eq true
            end
          end

          context 'not excluded extension return false' do
            let(:file_ext) { 'not_an_ext' }

            it 'returns false' do
              expect(described_class.derivative_excluded_ext_set? file_ext).to eq false
            end
          end
        end

        it "#file_set_actor_create_content" do
          ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
          skip "the test code goes here"
        end

        describe '#file_too_big' do
          let(:file_name2)          { "./some_non_existent_file" }
          let(:size_max_minus_one) { Rails.configuration.derivative_max_file_size - 1 }
          let(:size_max)           { Rails.configuration.derivative_max_file_size }
          let(:size_max_plus_one)  { Rails.configuration.derivative_max_file_size + 1 }

          context 'non-existent file' do
            it 'returns false' do
              expect(described_class.file_too_big file_name2).to eq false
            end
          end

          context 'existing file' do

            before do
              allow(File).to receive(:exist?).with(file_name2).and_return true
            end

            context 'under max size' do

              before do
                allow(File).to receive(:size).with(file_name2).and_return size_max_minus_one
              end

              it 'returns false' do
                expect(described_class.file_too_big file_name2).to eq false
              end

            end

            context 'equal max size' do

              before do
                allow(File).to receive(:size).with(file_name2).and_return size_max
              end

              it 'returns false' do
                expect(described_class.file_too_big file_name2).to eq false
              end

            end

            context 'over max size' do

              before do
                allow(File).to receive(:size).with(file_name2).and_return size_max_plus_one
              end

              it 'returns true' do
                expect(described_class.file_too_big file_name2).to eq true
              end

            end

          end

        end

        it "#ingest" do
          ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
          skip "the test code goes here"
        end

        it "#label_for" do
          ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
          skip "the test code goes here"
        end

        it "#log_error" do
          ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
          skip "the test code goes here"
        end

        it "#related_file" do
          ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
          skip "the test code goes here"
        end

        it "#perform_create_derivatives_job" do
          ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
          skip "the test code goes here"
        end

        it "#update_total_file_size" do
          ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
          skip "the test code goes here"
        end

        it "#virus_scan" do
          ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
          skip "the test code goes here"
        end

        it "#compose_e_msg" do
          ::Deepblue::LoggingHelper.bold_debug "The above has no bold_debug statements." if dbg_verbose
          skip "the test code goes here"
        end

        describe "call create derivative fail and recall" do
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

          let(:user)               { create(:user) }
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
              # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
              #                                        ::Deepblue::LoggingHelper.called_from,
              #                                        "JobStatus.all.count=#{JobStatus.all.count}" ]
              js = JobStatus.new( job_id: parent_job_id, job_class: parent_job_class )
              js.status = JobStatus::STARTED
              js.user_id = user.id
              js.save
              # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
              #                                        ::Deepblue::LoggingHelper.called_from,
              #                                        "JobStatus.all.count=#{JobStatus.all.count}" ]
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
              count = JobStatus.all.count
              expect {
                described_class.create_derivatives( file_set,
                                                    repository_file_id,
                                                    filepath,
                                                    current_user: user,
                                                    delete_input_file: true,
                                                    job_status: parent_job_status,
                                                    uploaded_file_ids: uploaded_file_ids ) }.to change(JobStatus, :count).by(0)
              job_status = JobStatus.all.last
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
    end
    it_behaves_like 'shared ::Deepblue::IngestHelper', false
    it_behaves_like 'shared ::Deepblue::IngestHelper', true
  end


end
