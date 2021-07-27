# frozen_string_literal: true

require 'rails_helper'

require_relative "../../lib/tasks/abstract_log_task"

class MockAbstractLogTask < ::Deepblue::AbstractLogTask

  def initialize( options: {}, pass_all_options: false )
    super
  end

end

RSpec.describe ::Deepblue::AbstractLogTask, skip: false do
  let( :logger ) { double("logger") }

  describe 'constants', skip: false do
    it "resolves them" do
      expect( described_class::DEFAULT_BEGIN ).to eq ''
      expect( described_class::DEFAULT_END ).to eq ''
      expect( described_class::DEFAULT_FORMAT ).to eq ''
      expect( described_class::DEFAULT_INPUT ).to eq './log/provenance_production.log'
      expect( described_class::DEFAULT_OUTPUT ).to eq ''
    end
  end

  describe ".initialize" do
    let( :options ) { { option1: 'value1' } }

    context "with hash options" do
      let( :options ) { { option1: 'value1' } }
      let( :task ) { described_class.new( options: options ) }

      before do
        expect( ::Deepblue::TaskHelper ).to receive( :logger_new ).with( no_args ).and_return logger
      end

      it "has the correct options" do
        expect( task.options ).to eq options
        expect( task.msg_queue ).to eq nil
        expect( task.to_console ).to eq ::Deepblue::AbstractTask::DEFAULT_TO_CONSOLE
        expect( task.verbose ).to eq ::Deepblue::AbstractTask::DEFAULT_VERBOSE
        expect( task.logger ).to eq logger
      end

    end

  end

end
