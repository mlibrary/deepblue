# frozen_string_literal: true

require 'rails_helper'

Rails.application.load_tasks

describe "report_files_missing_from_export.rake" do

  # reference: https://tasdikrahman.me/2020/10/20/testing-rake-tasks-with-rspec/

  context "report_files_missing_from_export" do

    let(:task)    { 'deepblue:report_files_missing_from_export' }
    let(:invoked) { ::Deepblue::ReportFilesMissingFromExport.new( options: {} ) }


    before do
      expect(::Deepblue::ReportFilesMissingFromExport).to receive(:new).with( any_args ).at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once)
    end

    after do
      Rake::Task[task].reenable
    end

    it "invokes Deepblue::ReportFilesMissingFromExport" do
      Rake::Task[task].invoke( options: {} )
    end

  end

end
