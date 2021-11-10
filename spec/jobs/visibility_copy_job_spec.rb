# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VisibilityCopyJob do

  describe 'an open access work' do
    let(:work) { create(:data_set_with_files) }

    it 'copies visibility to its contained files' do
      # files are private at the outset
      expect(work.file_sets.first.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE

      work.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      work.save
      described_class.perform_now(work)
      work.reload.file_sets.each do |file|
        expect(file.visibility).to eq 'open'
      end
    end
  end

  describe 'an embargoed work' do
    let(:work) { create(:embargoed_data_set_with_files) }
    let(:file) { work.file_sets.first }

    before do
      expect(work.visibility).to eq 'restricted'
      expect(work).to be_under_embargo
      expect(work.file_sets.first).not_to be_under_embargo
      described_class.perform_now(work)
      work.reload
    end

    it 'copies visibility to its contained files and apply a copy of the embargo to the files' do
      expect(file).to be_under_embargo
      expect(file.embargo.id).not_to eq work.embargo.id
    end
  end

  describe 'a leased work' do
    let(:work) { create(:leased_data_set_with_files) }
    let(:file) { work.file_sets.first }

    before do
      expect(work.visibility).to eq 'open'
      expect(work).to be_active_lease
      expect(work.file_sets.first).not_to be_active_lease
      described_class.perform_now(work)
      work.reload
    end

    it 'copies visibility to its contained files and apply a copy of the lease to the files' do
      expect(file).to be_active_lease
      expect(file.lease.id).not_to eq work.lease.id
    end
  end

end
