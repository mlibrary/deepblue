require 'rails_helper'

class MockAbstractFixer < ::Deepblue::AbstractFixer

  def initialize( debug_verbose: false,
                  filter: Deepblue::FindAndFixService.find_and_fix_default_filter,
                  prefix: 'AbstractPrefix: ',
                  task: false,
                  verbose: Deepblue::FindAndFixService.find_and_fix_default_verbose )

    super( debug_verbose: debug_verbose,
           filter: filter,
           prefix: prefix,
           task: task,
           verbose: verbose )
  end

  def fix( curation_concern:, msg_handler: )
    add_msg( curation_concern.to_s, msg_handler: msg_handler )
  end

end

class MockBrokenAbstractFixer < ::Deepblue::AbstractFixer

  def initialize( debug_verbose: false,
                  filter: nil,
                  prefix: 'AbstractPrefix: ',
                  task: false,
                  verbose: false )

    super( debug_verbose: debug_verbose,
           filter: filter,
           prefix: prefix,
           task: task,
           verbose: verbose )
  end

end

RSpec.describe ::Deepblue::AbstractFixer do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.abstract_fixer_debug_verbose ).to eq( debug_verbose ) }
  end

  let(:default_debug_verbose) { false }
  let(:default_filter)        { Deepblue::FindAndFixService.find_and_fix_default_filter }
  let(:default_prefix)        { 'AbstractPrefix: ' }
  let(:default_task)          { false }
  let(:default_verbose)       { Deepblue::FindAndFixService.find_and_fix_default_verbose }

  describe ".initialize" do
    let(:abstract_fixer) { MockAbstractFixer.allocate }

    context 'empty initializer' do
      it 'has default values' do
        abstract_fixer.send(:initialize)
        expect(abstract_fixer.debug_verbose).to  eq default_debug_verbose
        expect(abstract_fixer.filter).to         eq default_filter
        expect(abstract_fixer.prefix).to         eq default_prefix
        expect(abstract_fixer.task).to           eq default_task
        expect(abstract_fixer.verbose).to        eq default_verbose

        expect(abstract_fixer.ids_fixed).to      eq []
      end
    end

    context 'all values' do
      let(:debug_verbose) { default_debug_verbose }
      let(:filter)        { "filter" }
      let(:prefix)        { 'New ' + default_prefix }
      let(:task)          { !default_task }
      let(:verbose)       { !default_verbose }

      it 'has initialize values' do
        abstract_fixer.send(:initialize,
                            debug_verbose: debug_verbose,
                            filter: filter,
                            prefix: prefix,
                            task: task,
                            verbose: verbose )
        expect(abstract_fixer.debug_verbose).to  eq default_debug_verbose
        expect(abstract_fixer.filter).to         eq filter
        expect(abstract_fixer.prefix).to         eq prefix
        expect(abstract_fixer.task).to           eq task
        expect(abstract_fixer.verbose).to        eq verbose

        expect(abstract_fixer.ids_fixed).to      eq []
      end
    end

  end

  describe '.add_msg' do
    let(:abstract_fixer) { MockAbstractFixer.allocate }
    let(:prefix)         { 'Prefix:' }
    let(:msg_handler)    { ::Deepblue::MessageHandler.new }
    let(:msg)            { 'That was interesting.' }
    let(:msg2)           { 'Even more interesting.' }
    it 'adds the message to msg_handler' do
      abstract_fixer.send(:initialize, debug_verbose: false, prefix: prefix )
      abstract_fixer.add_msg( msg, msg_handler: msg_handler )
      expect( msg_handler.msg_queue ).to eq [ "#{prefix}#{msg}" ]
      abstract_fixer.add_msg(  msg2, msg_handler: msg_handler )
      expect( msg_handler.msg_queue ).to eq [ "#{prefix}#{msg}", "#{prefix}#{msg2}" ]
    end
  end

  describe '.fix' do

    context 'with defined fix method' do
      let(:abstract_fixer)   { MockAbstractFixer.allocate }
      let(:curation_concern) { "DataSet" }
      let(:msg_handler)      { ::Deepblue::MessageHandler.new }
      it 'adds the message to msg_handler' do
        abstract_fixer.send(:initialize)
        abstract_fixer.fix( curation_concern: curation_concern, msg_handler: msg_handler )
        expect( msg_handler.msg_queue ).to eq [ "#{default_prefix}#{curation_concern}" ]
      end
    end

    context 'without defined fix method' do
      let(:abstract_fixer)   { MockBrokenAbstractFixer.allocate }
      let(:curation_concern) { "DataSet" }
      let(:msg_handler)      { ::Deepblue::MessageHandler.new }
      it 'adds the message to msg_handler' do
        abstract_fixer.send(:initialize)
        expect { abstract_fixer.fix( curation_concern: curation_concern,
                                     msg_handler: msg_handler ) }.to raise_error "Attempt to call abstract method."
      end
    end

  end

  describe '.fix_include?' do
    let(:abstract_fixer)   { MockAbstractFixer.allocate }
    let(:curation_concern) { double("curation_concern") }
    let(:filter)           { "filter" }
    let(:msg_handler)      { ::Deepblue::MessageHandler.new }

    context 'nil filter filters in' do
      # before do
      #   allow(curation_concern).to receive(:what).and_return what
      # end
      it 'adds the message to msg_handler' do
        abstract_fixer.send(:initialize, filter: nil)
        expect(abstract_fixer.fix_include?( curation_concern: curation_concern, msg_handler: msg_handler )).to eq true
      end
    end

    context 'with filter' do
      let(:fake_date) { 'fake_date' }

      before do
        abstract_fixer.send(:initialize, filter: filter)
      end

      context 'filter in' do
        before do
          allow(curation_concern).to receive(:date_modified).and_return fake_date
          allow(filter).to receive(:include?).with(fake_date).and_return true
        end
        it 'adds the message to msg_handler' do
          expect(abstract_fixer.fix_include?( curation_concern: curation_concern, msg_handler: msg_handler )).to eq true
        end
      end

      context 'filter out' do
        before do
          allow(curation_concern).to receive(:date_modified).and_return fake_date
          allow(filter).to receive(:include?).with(fake_date).and_return false
        end
        it 'adds the message to msg_handler' do
          expect(abstract_fixer.fix_include?( curation_concern: curation_concern, msg_handler: msg_handler )).to eq false
        end
      end

    end

  end

end
