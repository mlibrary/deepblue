# frozen_string_literal: true

require 'rails_helper'

require_relative "../../lib/tasks/abstract_report_task"

RSpec.describe ::Deepblue::AbstractReportTask, skip: false do

  describe 'constants', skip: true do
    it "resolves them" do
      expect( described_class::DEFAULT_REPORT_FORMAT ).to eq 'report.yml'
    end
  end

end
