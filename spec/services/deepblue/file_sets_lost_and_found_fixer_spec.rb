# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Deepblue::FileSetsLostAndFoundFixer do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.file_sets_lost_and_found_fixer_debug_verbose ).to eq debug_verbose }
  end

  describe 'module Constants have the correct values' do
    it { expect( described_class::PREFIX ).to eq 'FileSet lost and found: ' }
  end

  let(:default_debug_verbose) { false }
  let(:default_filter)        { Deepblue::FindAndFixService.find_and_fix_default_filter }
  let(:lost_and_found_title)  { Deepblue::FindAndFixService.find_and_fix_file_sets_lost_and_found_work_title }
  let(:msg_handler)           { ::Deepblue::MessageHandler.new }

  describe ".initialize" do

    context 'empty initializer' do
      let(:fixer) { described_class.allocate }
      it 'has default values' do
        fixer.send(:initialize, msg_handler: msg_handler)
        expect(fixer.debug_verbose).to  eq default_debug_verbose
        expect(fixer.filter).to         eq default_filter
        expect(fixer.prefix).to         eq described_class::PREFIX
        expect(fixer.msg_handler).to    eq msg_handler

        expect(fixer.ids_fixed).to      eq []
      end
    end

    context 'all values' do
      let(:fixer) { described_class.allocate }
      let(:debug_verbose) { false }
      let(:filter)        { "filter" }

      it 'has initialize values' do
        fixer.send(:initialize,
                   filter: filter,
                   msg_handler: msg_handler )

        expect(fixer.debug_verbose).to  eq debug_verbose
        expect(fixer.filter).to         eq filter
        expect(fixer.prefix).to         eq described_class::PREFIX
        expect(fixer.msg_handler).to    eq msg_handler

        expect(fixer.ids_fixed).to      eq []
      end
    end

  end

  # context 'with multiple file_sets', skip: true do
  #   let(:work_v1) { create(:data_set) } # this version of the work has no members
  #
  #   before do # another file_set is added
  #     work_v1.ordered_members << create(:file_set)
  #     work_v1.save!
  #   end
  #
  #   it "now contains two file_sets" do
  #     expect(work_v1.members.size).to eq 2
  #   end
  # end

  describe 'methods are correct' do

    let(:parent_work) { create(:data_set, title: ['parent work']) }
    let(:lost_and_found_work) { create(:data_set, title: [lost_and_found_title])}
    let(:solr_query) { "+generic_type_sim:Work AND +title_tesim:#{lost_and_found_title}" }
    # let(:lost_and_found_work) do
    #   DataSet.new(title: [lost_and_found_title]).tap do |work|
    #     work.save!(validate: false)
    #   end
    # end
    let(:fix_included) { create(:file_set) }
    let(:fix_excluded) { create(:file_set) }
    let(:fixer) { described_class.new( msg_handler: msg_handler )}

    before do # another file_set is added
      parent_work.ordered_members << fix_excluded
      parent_work.save!
      allow(fixer).to receive(:init_lost_and_found_work).and_return lost_and_found_work
      # allow(::Hyrax::SolrService).to receive(:query).with( solr_query, rows: 10 ).and_return lost_and_found_work
    end

    context '.fix_include?' do

      it 'included' do
        expect( fixer.fix_include?( curation_concern: fix_included ) ).to eq true
        expect( msg_handler.msg_queue ).to eq []
      end

      it 'excluded' do
        expect( fixer.fix_include?( curation_concern: fix_excluded ) ).to eq false
        expect( msg_handler.msg_queue ).to eq []
      end

    end

    context '.fix' do
      let(:prefix) { described_class::PREFIX }

      before do
        msg_handler.verbose = true
      end

      context 'no lost and found work' do

        before do
          allow( fixer ).to receive(:init_lost_and_found_work).and_return nil
        end

        it 'reports that it would add to lost and found if it could find it' do
          fixer.fix( curation_concern: fix_included )
          expect( msg_handler.msg_queue ).to eq [ "#{prefix}FileSet #{fix_included.id} has no parent. Create DataSet with title #{lost_and_found_title}" ]
        end

      end

      context 'lost and found work' do

        it 'adds the file set to lost and found works' do
          expect( Array( lost_and_found_work.ordered_members ).empty? ).to eq true
          expect( lost_and_found_work.file_sets.empty? ).to eq true
          fixer.fix( curation_concern: fix_included )
          expect( msg_handler.msg_queue ).to eq [ "#{prefix}FileSet #{fix_included.id} added to lost and found work #{lost_and_found_work.id}" ]
          expect( Array( lost_and_found_work.ordered_members ) ).to eq [ fix_included ]
          expect( lost_and_found_work.file_sets ).to eq [ fix_included ]
        end

      end

    end

  end

end
