# frozen_string_literal: true

# keywords task_spec

require 'rails_helper'

Rails.application.load_tasks

require_relative '../../lib/tasks/globus_errors_report'
#require_relative '../../lib/tasks/globus_errors_report.rake'
require_relative '../../app/services/deepblue/globus_integration_service'

describe "globus errors report rake" do

  # reference: https://tasdikrahman.me/2020/10/20/testing-rake-tasks-with-rspec/

  context "task is run" do

    let(:options)  { {} }
    let(:quiet)    { false }
    let(:invoked)  { ::Deepblue::GlobusErrorsReport.new( options: options ) }
    let(:reporter) { ::Deepblue::GlobusReporter.allocate }

    before do
      expect( ::Deepblue::GlobusErrorsReport ).to receive(:new).with( options: options ).at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once).and_call_original
      expect(::Deepblue::GlobusIntegrationService).to receive(:globus_errors_report).with(quiet: true,
                                                                                          debug_verbose: false,
                                                                                          rake_task: true).at_least(:once).and_call_original
      expect(::Deepblue::GlobusReporter).to receive(:new).with( error_ids: {},
                                                                locked_ids: {},
                                                                prep_dir_ids: {},
                                                                prep_dir_tmp_ids: {},
                                                                ready_ids: {},
                                                                quiet: true,
                                                                as_html: true,
                                                                debug_verbose: false,
                                                                rake_task: true ).at_least(:once).and_return reporter
      expect(reporter).to receive(:run).at_least(:once)
    end

    after do
      Rake::Task["deepblue:globus_errors_report"].reenable
    end

    it "invokes Deepblue::GlobusErrorsReport" do
      Rake::Task["deepblue:globus_errors_report"].invoke( options )
    end

  end

end