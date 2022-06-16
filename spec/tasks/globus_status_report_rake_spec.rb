# frozen_string_literal: true

# keywords task_spec

require 'rails_helper'

Rails.application.load_tasks

require_relative '../../lib/tasks/globus_status_report'
#require_relative '../../lib/tasks/globus_status_report.rake'
require_relative '../../app/services/deepblue/globus_integration_service'

describe "globus errors report rake" do

  # reference: https://tasdikrahman.me/2020/10/20/testing-rake-tasks-with-rspec/

  context "task is run" do

    let(:options)  { {} }
    let(:quiet)    { false }
    let(:reporter) { ::Deepblue::GlobusReporter.allocate }
    let(:msg_handler) { ::Deepblue::MessageHandler.msg_handler_for( task: true ) }
    let(:invoked)  { ::Deepblue::GlobusStatusReport.new( msg_handler: msg_handler, options: options ) }

    before do
      allow(::Deepblue::MessageHandler).to receive(:msg_handler_for).with(task: true).and_return msg_handler
      expect( ::Deepblue::GlobusStatusReport ).to receive(:new).with( msg_handler: msg_handler,
                                                                      options: options ).at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once).and_call_original
      expect(::Deepblue::GlobusIntegrationService).to receive(:globus_status_report).with(quiet: true,
                                                                                          debug_verbose: false,
                                                                                          msg_handler: msg_handler,
                                                                                          rake_task: true).at_least(:once).and_call_original
      expect(::Deepblue::GlobusReporter).to receive(:new).with( error_ids: {},
                                                                locked_ids: {},
                                                                prep_dir_ids: {},
                                                                prep_dir_tmp_ids: {},
                                                                ready_ids: {},
                                                                msg_handler: msg_handler,
                                                                as_html: true,
                                                                debug_verbose: false,
                                                                options: { 'quiet' => true } ).at_least(:once).and_return reporter
      expect(reporter).to receive(:run).at_least(:once)
    end

    after do
      Rake::Task["deepblue:globus_status_report"].reenable
    end

    it "invokes Deepblue::GlobusStatusReport" do
      Rake::Task["deepblue:globus_status_report"].invoke( options )
    end

  end

end