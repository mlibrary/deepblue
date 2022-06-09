# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Deepblue::MessageHandler do

  # let(:debug_verbose) { false }
  #
  # describe 'debug verbose variables' do
  #   it { expect( described_class.message_handler_debug_verbose ).to eq debug_verbose }
  # end

  context 'initialize' do

    describe 'no parameters' do
      let( :handler ) { described_class.new }
      it { expect( handler.msg_queue ).to eq [] }
      it { expect( handler.task ).to eq false }
      it { expect( handler.verbose ).to eq false }
    end

    describe 'with msg_queue' do
      it { expect( described_class.new( msg_queue: nil ).msg_queue ).to eq nil }
      it { expect( described_class.new( msg_queue: [] ).msg_queue ).to eq [] }
      it { expect( described_class.new( msg_queue: ['msg'] ).msg_queue ).to eq ['msg'] }
    end

    describe 'with task' do
      it { expect( described_class.new( task: true ).task ).to eq true }
      it { expect( described_class.new( task: false ).task ).to eq false }
    end

    describe 'with verbose' do
      it { expect( described_class.new( verbose: true ).verbose ).to eq true }
      it { expect( described_class.new( verbose: false ).verbose ).to eq false }
    end

  end

  context 'accessors work' do
    let( :handler ) { described_class.new }

    it '#msg_queue' do
      expect( handler.msg_queue ).to eq []
      handler.msg_queue = nil; expect( handler.msg_queue ).to eq nil
      handler.msg_queue = []; expect( handler.msg_queue ).to eq []
      handler.msg_queue = ['1', '2']; expect( handler.msg_queue ).to eq ['1', '2']
    end

    it '#task' do
      expect( handler.task ).to eq false
      handler.task = true;  expect( handler.task ).to eq true
      handler.task = false; expect( handler.task ).to eq false
    end

    it '#verbose' do
      expect( handler.verbose ).to eq false
      handler.verbose = true;  expect( handler.verbose ).to eq true
      handler.verbose = false; expect( handler.verbose ).to eq false
    end

  end

  context '#join' do
    let( :msg_queue_nil ) { nil }
    let( :msg_queue0 ) { [] }
    let( :msg_queue1 ) { ['line 1'] }
    let( :msg_queue2 ) { ['line 1', 'line 2'] }
    let( :sep ) { '-' }

    it 'correctly joins with no separator' do
      expect( described_class.new( msg_queue: msg_queue_nil ).join ).to eq ''
      expect( described_class.new( msg_queue: msg_queue0 ).join ).to eq msg_queue0.join
      expect( described_class.new( msg_queue: msg_queue1 ).join ).to eq msg_queue1.join
      expect( described_class.new( msg_queue: msg_queue2 ).join ).to eq msg_queue2.join
    end

    it 'correctly joins with separator' do
      expect( described_class.new( msg_queue: msg_queue_nil ).join(sep) ).to eq ''
      expect( described_class.new( msg_queue: msg_queue0 ).join(sep) ).to eq msg_queue0.join(sep)
      expect( described_class.new( msg_queue: msg_queue1 ).join(sep) ).to eq msg_queue1.join(sep)
      expect( described_class.new( msg_queue: msg_queue2 ).join(sep) ).to eq msg_queue2.join(sep)
    end

  end

  context 'correctly handle msg and msg_verbose' do

    describe 'default initialization' do
      let( :handler ) { described_class.new }
      it 'add message to queue' do
        expect do
          handler.msg 'line'
        end.to_not output('line').to_stdout
        expect( handler.msg_queue ).to eq ['line']
      end
      context 'msg_verbose' do
        it 'does not add message to queue' do
          expect do
            handler.msg_verbose 'line'
          end.to_not output('line').to_stdout
          expect( handler.msg_queue ).to eq []
        end
      end
    end

    describe 'with msg_queue initialized with non-empty array' do
      let( :msg_queue ) { ['line'] }
      let( :handler ) { described_class.new( msg_queue: msg_queue ) }
      it 'add message to queue' do
        expect do
          handler.msg 'line 2'
        end.to_not output('line 2').to_stdout
        expect( handler.msg_queue ).to eq ['line', 'line 2']
      end
      context 'msg_verbose' do
        it 'does not add message to queue when verbose false' do
          expect do
            handler.msg_verbose 'line 2'
          end.to_not output('line 2').to_stdout
          expect( handler.msg_queue ).to eq ['line']
        end
        it 'add message to queue when verbose true' do
          handler.verbose = true
          expect do
            handler.msg_verbose 'line 2'
          end.to_not output('line 2').to_stdout
          expect( handler.msg_queue ).to eq ['line', 'line 2']
        end
      end
    end

    describe 'with task true and msg_queue' do
      let( :handler ) { described_class.new( task: true ) }
      it 'add message to queue and print' do
        expect do
          handler.msg 'line'
        end.to output("line\n").to_stdout
        expect( handler.msg_queue ).to eq ['line']
      end
      context 'msg_verbose' do
        it 'does not add message to queue or print when verbose false' do
          expect do
            handler.msg_verbose 'line'
          end.to_not output("line\n").to_stdout
          expect( handler.msg_queue ).to eq []
        end
        it 'add message to queue and print when verbose true' do
          handler.verbose = true
          expect do
            handler.msg_verbose 'line'
          end.to output("line\n").to_stdout
          expect( handler.msg_queue ).to eq ['line']
        end
      end
    end

    describe 'with task true and msg_queue nil' do
      let( :handler ) { described_class.new( task: true, msg_queue: nil ) }
      it 'add message to queue and print' do
        expect do
          handler.msg 'line'
        end.to output("line\n").to_stdout
        expect( handler.msg_queue ).to eq nil
      end
      context 'msg_verbose' do
        it 'does not add message to queue or print when verbose false' do
          expect do
            handler.msg_verbose 'line'
          end.to_not output("line\n").to_stdout
          expect( handler.msg_queue ).to eq nil
        end
        it 'add message to queue and print when verbose true' do
          handler.verbose = true
          expect do
            handler.msg_verbose 'line'
          end.to output("line\n").to_stdout
          expect( handler.msg_queue ).to eq nil
        end
      end
    end

  end

end
