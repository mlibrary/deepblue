# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Deepblue::FindAndFix do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.find_and_fix_job_debug_verbose ).to eq debug_verbose }
  end

  describe 'module variables have the expected values' do
    it { expect( ::Deepblue::FindAndFixService.find_and_fix_default_verbose ).to eq true }
    it { expect( ::Deepblue::FindAndFixService.find_and_fix_empty_file_sizes_debug_verbose ).to eq false }
    it { expect( ::Deepblue::FindAndFixService.find_and_fix_file_sets_lost_and_found_work_title )
           .to eq 'DBD_Find_and_Fix_FileSets_Lost_and_Found' }
  end

  describe 'module related variables have the expected values' do
    it { expect( ::Deepblue::FindAndFixService.find_and_fix_over_collections ).to eq [] }
    it { expect( ::Deepblue::FindAndFixService.find_and_fix_over_file_sets ).to eq [
                                             'Deepblue::FileSetsEmbargoFixer',
                                             'Deepblue::FileSetsFileSizeFixer',
                                             'Deepblue::FileSetsLostAndFoundFixer',
                                             'Deepblue::FileSetsVisibilityFixer' ] }
    it { expect( ::Deepblue::FindAndFixService.find_and_fix_over_works ).to eq [
                                             'Deepblue::WorksOrderedMembersNilsFixer',
                                             'Deepblue::WorksOrderedMembersFileSetsSizeFixer',
                                             'Deepblue::WorksTotalFileSizeFixer',
                                             'Deepblue::WorksFileSetsNotLostFixer',
                                             'Deepblue::WorksFileSetsVisibilityFixer' ] }
  end

  def expected_fixers_after_initialization(find_and_fix)
    expect(find_and_fix.find_and_fix_collections_fixers).to eq []
    expect(find_and_fix.find_and_fix_file_sets_fixers.size).to eq 4
    expect(find_and_fix.find_and_fix_file_sets_fixers.select { |f| f.is_a? ::Deepblue::FileSetsEmbargoFixer }.size ).to eq 1
    expect(find_and_fix.find_and_fix_file_sets_fixers.select { |f| f.is_a? ::Deepblue::FileSetsFileSizeFixer }.size ).to eq 1
    expect(find_and_fix.find_and_fix_file_sets_fixers.select { |f| f.is_a? ::Deepblue::FileSetsLostAndFoundFixer }.size ).to eq 1
    expect(find_and_fix.find_and_fix_file_sets_fixers.select { |f| f.is_a? ::Deepblue::FileSetsVisibilityFixer }.size ).to eq 1
    expect(find_and_fix.find_and_fix_works_fixers.size).to eq 5
    expect(find_and_fix.find_and_fix_works_fixers.select { |f| f.is_a? ::Deepblue::WorksOrderedMembersFileSetsSizeFixer }.size ).to eq 1
    expect(find_and_fix.find_and_fix_works_fixers.select { |f| f.is_a? ::Deepblue::WorksOrderedMembersNilsFixer }.size ).to eq 1
    expect(find_and_fix.find_and_fix_works_fixers.select { |f| f.is_a? ::Deepblue::WorksTotalFileSizeFixer }.size ).to eq 1
    expect(find_and_fix.find_and_fix_works_fixers.select { |f| f.is_a? ::Deepblue::WorksFileSetsNotLostFixer }.size ).to eq 1
    expect(find_and_fix.find_and_fix_works_fixers.select { |f| f.is_a? ::Deepblue::WorksFileSetsVisibilityFixer }.size ).to eq 1
  end

  let(:default_debug_verbose) { false }
  let(:default_filter)        { ::Deepblue::FindAndFixService.find_and_fix_default_filter }
  let(:default_messages)      { [] }
  let(:default_verbose)       { false }

  describe ".initialize" do
    let(:find_and_fix) { described_class.allocate }

    context 'minimal initializer' do
      let(:msg_handler)           { ::Deepblue::MessageHandler.new }

      it 'has default values' do
        find_and_fix.send(:initialize, msg_handler: msg_handler)
        expect(find_and_fix.debug_verbose).to  eq default_debug_verbose
        expect(find_and_fix.filter).to         eq default_filter
        expect(find_and_fix.msg_handler).to    eq msg_handler
        expect(find_and_fix.msg_handler.msg_queue).to eq default_messages

        expect(find_and_fix.ids_fixed).to      eq( {} )
        expected_fixers_after_initialization(find_and_fix)
      end
    end

    context 'all values' do
      let(:debug_verbose) { !default_debug_verbose }
      let(:filter)        { "filter" }
      let(:msg_handler)   { ::Deepblue::MessageHandler.new( msg_queue: [ 'previous message' ] ) }
      let(:verbose)       { !default_verbose }

      it 'has initialize values' do
        find_and_fix.send(:initialize,
                          filter: filter,
                          msg_handler: msg_handler )
        expect(find_and_fix.debug_verbose).to  eq default_debug_verbose
        expect(find_and_fix.filter).to         eq filter
        expect(find_and_fix.msg_handler).to    eq msg_handler

        expect(find_and_fix.ids_fixed).to      eq( {} )
        expected_fixers_after_initialization(find_and_fix)
      end
    end

  end


end
