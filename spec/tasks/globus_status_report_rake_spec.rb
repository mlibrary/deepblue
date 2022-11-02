# frozen_string_literal: true

# keywords task_spec

require 'rails_helper'

Rails.application.load_tasks

require_relative '../../lib/tasks/globus_status_report'
require_relative '../../app/services/deepblue/globus_integration_service'

describe "globus errors report rake" do

  # reference: https://tasdikrahman.me/2020/10/20/testing-rake-tasks-with-rspec/

  context "task is run" do

    let(:options)  { {} }
    let(:quiet)    { false }
    let(:reporter) { ::Deepblue::GlobusReporter.allocate }
    let(:msg_handler) { ::Deepblue::MessageHandler.msg_handler_for( task: true, to_console: false ) }
    let(:invoked)  { ::Deepblue::GlobusStatusReport.new( msg_handler: msg_handler, options: options ) }
    let(:globus_status) { double(::Deepblue::GlobusStatus) }
    let(:globus_reporter) { double(::Deepblue::GlobusReporter) }

    before do
      allow(::Deepblue::MessageHandler).to receive(:msg_handler_for).with(task: true).and_return msg_handler
      expect(::Deepblue::GlobusStatusReport).to receive(:new).with(msg_handler: msg_handler,
                                                                   options: options ).at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once).and_call_original
      expect(::Deepblue::GlobusService).to receive(:globus_status_report).with(
                                                  msg_handler: msg_handler).at_least(:once).and_return globus_status
      allow(globus_status).to receive(:out).and_return globus_reporter
    end

    after do
      Rake::Task["deepblue:globus_status_report"].reenable
    end

    it "invokes Deepblue::GlobusStatusReport" do
      Rake::Task["deepblue:globus_status_report"].invoke( options )
    end

  end

end