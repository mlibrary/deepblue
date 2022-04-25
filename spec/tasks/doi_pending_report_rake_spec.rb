# frozen_string_literal: true

# keywords task_spec

require 'rails_helper'

Rails.application.load_tasks

require_relative '../../lib/tasks/doi_pending_report_task'
require_relative '../../app/services/deepblue/doi_pending_reporter'

describe "doi pending report rake" do

  # reference: https://tasdikrahman.me/2020/10/20/testing-rake-tasks-with-rspec/

  context "task is run" do

    let(:options)  { {} }
    let(:quiet)    { false }
    let(:invoked)  { ::Deepblue::DoiPendingReportTask.new( options: options ) }

    before do
      expect( ::Deepblue::DoiPendingReportTask ).to receive(:new).with( options: options ).at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once).and_call_original
      expect(::Deepblue::DoiMintingService).to receive(:doi_pending_finder).with( data_set_ids_found: [],
                                                                                  file_set_ids_found: [],
                                                                                  debug_verbose: false,
                                                                                  rake_task: true).at_least(:once).and_call_original
    end

    after do
      Rake::Task["deepblue:doi_pending_report"].reenable
    end

    it "invokes Deepblue::DoiPendingReport" do
      Rake::Task["deepblue:doi_pending_report"].invoke( options )
    end

  end

end