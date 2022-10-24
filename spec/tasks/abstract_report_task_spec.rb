# frozen_string_literal: true

require 'rails_helper'

require_relative "../../lib/tasks/abstract_report_task"

class MockAbstractReportTask < ::Deepblue::AbstractReportTask

end

RSpec.describe ::Deepblue::AbstractReportTask, skip: false do
  let( :logger ) { double("logger") }

  describe 'constants', skip: false do
    it "resolves them" do
      expect( described_class::DEFAULT_REPORT_FORMAT ).to eq 'report.yml'
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
        expect( task.options ).to eq options.with_indifferent_access
        expect( task.to_console ).to eq true
        expect( task.verbose ).to eq false
        expect( task.logger ).to eq logger
      end

    end

    context "with json options" do
      let( :task ) { described_class.new( options: ActiveSupport::JSON.encode( options ) ) }
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

  end

  context ".initialize_input" do
    let( :options ) { { option1: 'value1' } }
    let( :task ) { described_class.new( options: options ) }

    it "returns default value" do
      expect( task.initialize_input ).to eq described_class::DEFAULT_REPORT_FORMAT
    end

  end

end
