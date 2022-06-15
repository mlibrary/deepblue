# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Deepblue::WorksOrderedMembersNilsFixer do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.works_ordered_members_nils_fixer_debug_verbose ).to eq debug_verbose }
  end

  describe 'module Constants have the correct values' do
    it { expect( described_class::PREFIX ).to eq 'WorksOrderedMembers nils: ' }
  end

  let(:default_debug_verbose) { false }
  let(:default_filter)        { Deepblue::FindAndFixService.find_and_fix_default_filter }
  let(:default_task)          { false }
  let(:default_verbose)       { Deepblue::FindAndFixService.find_and_fix_default_verbose }
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
        expect(fixer.verbose).to        eq default_verbose

        expect(fixer.ids_fixed).to      eq []
      end
    end

    context 'all values' do
      let(:fixer) { described_class.allocate }
      let(:debug_verbose) { false }
      let(:filter)        { "filter" }
      let(:verbose)       { !default_verbose }

      it 'has initialize values' do
        fixer.send(:initialize,
                   debug_verbose: debug_verbose,
                   filter: filter,
                   msg_handler: msg_handler,
                   verbose: verbose )

        expect(fixer.debug_verbose).to  eq debug_verbose
        expect(fixer.filter).to         eq filter
        expect(fixer.prefix).to         eq described_class::PREFIX
        expect(fixer.msg_handler).to    eq msg_handler
        expect(fixer.verbose).to        eq verbose

        expect(fixer.ids_fixed).to      eq []
      end
    end

  end

  describe 'methods are correct' do
    let(:fixed) { create(:data_set) }
    let(:not_fixed) { create(:data_set) }
    let(:fixer) { described_class.new( msg_handler: msg_handler, verbose: true )}
    let(:one_nil_array) { [ nil ] }
    let(:file_set1) { create(:file_set) }

    before do # another file_set is added
      allow(fixed).to receive(:ordered_members).and_return(one_nil_array)
      not_fixed.ordered_members << file_set1
      not_fixed.save!
    end

    context '.fix_include?' do

      it 'include fixed' do
        expect( fixer.fix_include?( curation_concern: fixed ) ).to eq true
        expect( msg_handler.msg_queue ).to eq []
      end

      it 'include not_fixed' do
        expect( fixer.fix_include?( curation_concern: not_fixed ) ).to eq true
        expect( msg_handler.msg_queue ).to eq []
      end

    end

    context '.fix' do
      let(:prefix) { described_class::PREFIX }

      context 'fix nils in ordered members' do

        before do # another file_set is added
          allow(fixed).to receive(:ordered_members).and_return(one_nil_array)
          allow(fixed).to receive(:ordered_members=)
          not_fixed.ordered_members << file_set1
          not_fixed.save!
        end

        it 'is fixed' do
          fixer.fix( curation_concern: fixed )
          expect( msg_handler.msg_queue ).to eq [ "#{prefix}Compacting ordered_members for work #{fixed.id}." ]
        end

        it 'is not fixed' do
          fixer.fix( curation_concern: not_fixed )
          expect( msg_handler.msg_queue ).to eq []
        end

      end

    end

  end

end
