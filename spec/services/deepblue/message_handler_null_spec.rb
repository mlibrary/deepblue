# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Deepblue::MessageHandlerNull do

  # let(:debug_verbose) { false }
  #
  # describe 'debug verbose variables' do
  #   it { expect( described_class.message_handler_null_debug_verbose ).to eq debug_verbose }
  # end
  context 'initialize' do

    describe 'no parameters' do
      let( :handler ) { described_class.new }
      it { expect( handler.msg_queue ).to eq nil }
      it { expect( handler.task ).to eq false }
      it { expect( handler.verbose ).to eq false }
    end

    describe 'with msg_queue' do
      it { expect( described_class.new( msg_queue: nil ).msg_queue ).to eq nil }
      it { expect( described_class.new( msg_queue: [] ).msg_queue ).to eq nil }
      it { expect( described_class.new( msg_queue: ['msg'] ).msg_queue ).to eq nil }
    end

    describe 'with task' do
      it { expect( described_class.new( task: true ).task ).to eq false }
      it { expect( described_class.new( task: false ).task ).to eq false }
    end

    describe 'with verbose' do
      it { expect( described_class.new( verbose: true ).verbose ).to eq false }
      it { expect( described_class.new( verbose: false ).verbose ).to eq false }
    end

  end

  context 'accessors work (but who cares?)' do
    let( :handler ) { described_class.new }

    it '#msg_queue' do
      expect( handler.msg_queue ).to eq nil
      handler.msg_queue = nil; expect( handler.msg_queue ).to eq nil
      handler.msg_queue = []; expect( handler.msg_queue ).to eq nil
      handler.msg_queue = ['1', '2']; expect( handler.msg_queue ).to eq nil
    end

    it '#task' do
      expect( handler.task ).to eq false
      handler.task = true;  expect( handler.task ).to eq false
      handler.task = false; expect( handler.task ).to eq false
    end

    it '#verbose' do
      expect( handler.verbose ).to eq false
      handler.verbose = true;  expect( handler.verbose ).to eq false
      handler.verbose = false; expect( handler.verbose ).to eq false
    end

    context '#join' do
      let( :msg_queue_nil ) { nil }
      let( :msg_queue0 ) { [] }
      let( :msg_queue1 ) { ['line 1'] }
      let( :msg_queue2 ) { ['line 1', 'line 2'] }
      let( :sep ) { '-' }
      let( :expect_join ) { '' }

      it 'correctly joins with no separator' do
        expect( described_class.new( msg_queue: msg_queue_nil ).join ).to eq expect_join
        expect( described_class.new( msg_queue: msg_queue0 ).join ).to eq expect_join
        expect( described_class.new( msg_queue: msg_queue1 ).join ).to eq expect_join
        expect( described_class.new( msg_queue: msg_queue2 ).join ).to eq expect_join
      end

      it 'correctly joins with separator' do
        expect( described_class.new( msg_queue: msg_queue_nil ).join(sep) ).to eq expect_join
        expect( described_class.new( msg_queue: msg_queue0 ).join(sep) ).to eq expect_join
        expect( described_class.new( msg_queue: msg_queue1 ).join(sep) ).to eq expect_join
        expect( described_class.new( msg_queue: msg_queue2 ).join(sep) ).to eq expect_join
      end

    end

  end

  context 'correctly handle msg and verbose' do

    let( :expected_msg_queue ) { nil }

    describe 'default initialization' do
      # any initialization parameters are ignored, so just need default
      let( :handler ) { described_class.new }
      it 'does not add message to queue' do
        expect do
          handler.msg 'line'
        end.to_not output("line\n").to_stdout
        expect( handler.msg_queue ).to eq expected_msg_queue
      end
      context 'msg_verbose' do
        it 'does not add message to queue' do
          expect do
            handler.msg_verbose 'line'
          end.to_not output("line\n").to_stdout
          expect( handler.msg_queue ).to eq expected_msg_queue
        end
      end
    end

  end

end
