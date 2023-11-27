# frozen_string_literal: true

require 'rails_helper'

Rails.application.load_tasks

describe "run_report.rake" do

  # reference: https://tasdikrahman.me/2020/10/20/testing-rake-tasks-with-rspec/

  context "run_report" do

    let(:task)    { 'deepblue:run_report' }
    let(:invoked) { ::Deepblue::ReportTask.new( report_definitions_file: nil, options: {} ) }


    before do
      expect(::Deepblue::ReportTask).to receive(:new).with( any_args ).at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once)
    end

    after do
      Rake::Task[task].reenable
    end

    it "invokes Deepblue::ReportTask" do
      Rake::Task[task].invoke( report_definitions_file: nil, options: {} )
    end

  end

end
