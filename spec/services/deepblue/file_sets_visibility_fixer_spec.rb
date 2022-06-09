# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Deepblue::FileSetsVisibilityFixer do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( subject.file_sets_visibility_fixer_debug_verbose ).to eq debug_verbose }
  end

  describe 'module Constants have the correct values' do
    it { expect( described_class::PREFIX ).to eq 'FileSet visibility: ' }
  end

  let(:default_debug_verbose) { false }
  let(:default_filter)        { Deepblue::FindAndFixService.find_and_fix_default_filter }
  let(:default_task)          { false }
  let(:default_verbose)       { Deepblue::FindAndFixService.find_and_fix_default_verbose }

  describe ".initialize" do

    context 'empty initializer' do
      let(:fixer) { described_class.allocate }
      it 'has default values' do
        fixer.send(:initialize)
        expect(fixer.debug_verbose).to  eq default_debug_verbose
        expect(fixer.filter).to         eq default_filter
        expect(fixer.prefix).to         eq described_class::PREFIX
        expect(fixer.task).to           eq default_task
        expect(fixer.verbose).to        eq default_verbose

        expect(fixer.ids_fixed).to      eq []
      end
    end

    context 'all values' do
      let(:fixer) { described_class.allocate }
      let(:debug_verbose) { false }
      let(:filter)        { "filter" }
      let(:task)          { !default_task }
      let(:verbose)       { !default_verbose }

      it 'has initialize values' do
        fixer.send(:initialize,
                   debug_verbose: debug_verbose,
                   filter: filter,
                   task: task,
                   verbose: verbose )

        expect(fixer.debug_verbose).to  eq debug_verbose
        expect(fixer.filter).to         eq filter
        expect(fixer.prefix).to         eq described_class::PREFIX
        expect(fixer.task).to           eq task
        expect(fixer.verbose).to        eq verbose

        expect(fixer.ids_fixed).to      eq []
      end
    end

  end

  describe 'methods are correct' do
    let(:visible)     { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
    let(:not_visible) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }

    let(:parent_work) { create(:data_set, title: ['parent work'], visibility: visible ) }
    let(:fix_included) { create(:file_set, visibility: visible ) }
    let(:fix_included_and_fix) { create(:file_set, visibility: not_visible ) }
    let(:fix_excluded) { create(:file_set) }
    let(:msg_handler) { ::Deepblue::MessageHandler.new }
    let(:fixer) { described_class.new( verbose: true )}

    before do # another file_set is added
      parent_work.ordered_members << fix_included_and_fix
      parent_work.ordered_members << fix_included
      parent_work.save!
    end

    context '.fix_include?' do

      it 'included' do
        expect( fixer.fix_include?( curation_concern: fix_included, msg_handler: msg_handler ) ).to eq true
        expect( msg_handler.msg_queue ).to eq []
      end

      it 'excluded' do
        expect( fixer.fix_include?( curation_concern: fix_excluded, msg_handler: msg_handler ) ).to eq false
        expect( msg_handler.msg_queue ).to eq []
      end

    end

    context '.fix' do
      let(:prefix) { described_class::PREFIX }

      context 'fix visibility' do

        it 'is fixed' do
          expect( parent_work.visibility == fix_included_and_fix.visibility ).to eq false
          fixer.fix( curation_concern: fix_included_and_fix, msg_handler: msg_handler )
          expect( msg_handler.msg_queue ).to eq [ "#{prefix}FileSet #{fix_included_and_fix.id} parent work #{parent_work.id} updating visibility." ]
          expect( parent_work.visibility == fix_included_and_fix.visibility ).to eq true
        end

        it 'is not fixed' do
          expect( parent_work.visibility == fix_included.visibility ).to eq true
          fixer.fix( curation_concern: fix_included, msg_handler: msg_handler )
          expect( msg_handler.msg_queue ).to eq []
          expect( parent_work.visibility == fix_included.visibility ).to eq true
        end

      end

    end

  end

end
