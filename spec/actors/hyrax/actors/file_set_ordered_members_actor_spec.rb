require 'rails_helper'

RSpec.describe Hyrax::Actors::FileSetOrderedMembersActor, skip: false do
  include ActionDispatch::TestProcess

  let(:user)          { create(:user) }
  let(:file_path)     { File.join(fixture_path, 'world.png') }
  let(:file)          { fixture_file_upload(file_path, 'image/png') } # we will override for the different types of File objects
  let(:local_file)    { File.open(file_path) }
  let(:file_set)      { create(:file_set, content: local_file) }
  let(:actor)         { described_class.new(file_set, user) }
  let(:relation)      { :original_file }
  let(:file_actor)    { Hyrax::Actors::FileActor.new(file_set, relation, user) }

  let( :job )          { TestJob.send( :job_or_instantiate ) }
  let( :job_id )       { job.job_id }
  let(:job_status_var) { JobStatus.create( job_id: job_id, job_class: job.class ) }
  let(:job_status)     { IngestJobStatus.new( job_status: job_status_var, verbose: false, main_cc_id: nil, user_id: user.id  ) }

  describe 'creating metadata, content and attaching to a work' do
    let(:work) { create(:data_set) }
    let(:date_today) { DateTime.current }

    subject { file_set.reload }

    before do
      allow(DateTime).to receive(:current).and_return(date_today)
      allow(actor).to receive(:acquire_lock_for).and_yield
      actor.create_metadata
      actor.create_content(file, job_status: job_status)
      actor.attach_to_work(work)
    end

    context 'when a work is provided' do
      it 'does not add the FileSet to the parent work' do
        expect(subject.parents).to eq []
        expect(subject.visibility).to eq 'restricted'
        expect(work.reload.file_sets).not_to include(subject)
      end
    end
  end
end
