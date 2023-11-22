# frozen_string_literal: true

require 'rails_helper'

require_relative "../../app/tasks/deepblue/abstract_provenance_log_task"

class MockAbstractProvenanceLogTask < ::Deepblue::AbstractProvenanceLogTask

  def initialize( options: {} )
    super
  end

end

RSpec.describe ::Deepblue::AbstractProvenanceLogTask, skip: false do
  let( :logger ) { double("logger") }

  describe ".initialize" do
    let( :options ) { { option1: 'value1' } }

    context "with hash options" do
      let( :options ) { { option1: 'value1' } }
      let( :task ) { described_class.new( options: options ) }

      before do
        expect( ::Deepblue::TaskHelper ).to receive( :logger_new ).with( no_args ).and_return logger
      end

      it "has the correct options" do
        expect( task.options ).to eq options.with_indifferent_access
        expect( task.to_console ).to eq true
        expect( task.verbose ).to eq false
        expect( task.logger ).to eq logger
      end

    end

  end

end
