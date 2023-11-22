# frozen_string_literal: true

require 'rails_helper'

require_relative "../../app/tasks/deepblue/abstract_task"

class MockAbstractTask < ::Deepblue::AbstractTask

  def initialize( msg_handler: nil, options: {} )
    super( msg_handler: msg_handler, options: options )
  end

end

RSpec.describe ::Deepblue::AbstractTask, skip: false do
  let( :logger ) { double("logger") }
  let( :options1 ) { { option1: 'value1' } }

  describe 'constants', skip: false do
    it "resolves them" do
      # expect( described_class::DEFAULT_TO_CONSOLE ).to eq true
      # expect( described_class::DEFAULT_VERBOSE ).to eq false
    end
  end

  describe ".initialize" do

    context "with hash options" do
      let( :task ) { MockAbstractTask.new( options: options1) }

      before do
        expect( ::Deepblue::TaskHelper ).to receive( :logger_new ).with( no_args ).and_return logger
      end

      it "has the correct options" do
        expect( task.options ).to eq options1.with_indifferent_access
        expect( task.to_console ).to eq true
        expect( task.verbose ).to eq false
        expect( task.logger ).to eq logger
      end

    end

    context "with json options" do
      let( :task ) { MockAbstractTask.new( options: ActiveSupport::JSON.encode( options1 ) ) }
      let( :options_expected ) { {"option1"=>"value1"} }

      before do
        expect( ::Deepblue::TaskHelper ).to receive( :logger_new ).with( no_args ).and_return logger
      end

      it "has the correct options" do
        expect( task.options ).to eq options_expected
        expect( task.to_console ).to eq true
        expect( task.verbose ).to eq false
        expect( task.logger ).to eq logger
      end

    end

    context "with bad json options string" do
      let( :options_str ) { '{' }
      let( :task ) { MockAbstractTask.new(msg_handler: ::Deepblue::MessageHandler.new(msg_queue: []),
                                          options: options_str) }
      let( :options_expected ) { {"option1"=>"value1"} }

      before do
        expect( ::Deepblue::TaskHelper ).to receive( :logger_new ).with( no_args ).and_return logger
      end

      it "has the correct options" do
        expect( task.options.size ).to eq 2
        expect( task.options.has_key?( :error ) ).to eq true
        expect( task.options[:options_str] ).to eq options_str
        expect( task.msg_handler.msg_queue.size ).to eq 2
        expect( task.msg_handler.msg_queue[0] ).to match /WARNING: options error 8\d\d: unexpected token at '\{'/
        expect( task.msg_handler.msg_queue[1] ).to eq "options=#{options_str}"
        expect( task.to_console ).to eq false
        expect( task.verbose ).to eq false
        expect( task.logger ).to eq logger
      end

    end

  end

  describe ".logger_initialize" do
    let( :task ) { MockAbstractTask.new( options: options1 ) }

    before do
      expect( ::Deepblue::TaskHelper ).to receive( :logger_new ).with( no_args ).and_return logger
    end

    it "calls logger new on TaskHelper" do
      expect(task.send( :logger_initialize )).to eq logger
    end

  end


end
