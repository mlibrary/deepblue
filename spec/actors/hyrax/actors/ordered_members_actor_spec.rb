require 'rails_helper'
require 'redlock'

RSpec.describe Hyrax::Actors::OrderedMembersActor, skip: false do
  include ActionDispatch::TestProcess

  let(:user)          { factory_bot_create_user(:user) }
  let(:actor)         { described_class.new([file_set], user) }
  let(:file_set) { build(:file_set) }
  let(:work) { create(:data_set) }

  describe 'attaching to a work' do
    before do
      allow(actor).to receive(:acquire_lock_for).and_yield
      actor.attach_ordered_members_to_work(work)
    end

    context 'when a work is provided' do
      it 'adds the FileSet to the parent work' do
        expect(file_set.parents).to eq [work]
        expect(work.reload.file_sets).to include(file_set)
      end
    end

    context 'with multiple file_sets' do
      let(:work_v1) { create(:data_set) } # this version of the work has no members

      before do # another file_set is added
        work.ordered_members << create(:file_set)
        work.save!
      end

      it "now contains two file_sets" do
        expect(work.members.size).to eq 2
      end
    end

    context 'with multiple versions' do
      let(:work_v1) { create(:data_set) } # this version of the work has no members

      before do # another version of the same work is saved with a member
        work_v2 = PersistHelper.find(work_v1.id)
        work_v2.ordered_members << create(:file_set)
        work_v2.save!
      end

      it "writes to the most up to date version" do
        actor.attach_ordered_members_to_work(work_v1)
        expect(work_v1.members.size).to eq 2
      end
    end
  end

  describe "#runs callbacks" do
    it 'runs callbacks' do
      expect(Hyrax::FileSetAttachedEventJob).to receive(:perform_later).with(file_set, user)
      actor.attach_ordered_members_to_work(work)
    end
  end

end
