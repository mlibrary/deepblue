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
    let(:msg_handler) { instance_double(::Deepblue::MessageHandler) }

    before do
      expect(::Deepblue::MessageHandler).to receive(:new).with(debug_verbose: false,
                                                               msg_prefix: '',
                                                               msg_queue: nil,
                                                               to_console: true,
                                                               verbose: false).and_return msg_handler
      allow(msg_handler).to receive(:msg).with(any_args)
      allow(msg_handler).to receive(:msg_verbose).with(any_args)
      allow(msg_handler).to receive(:debug_verbose).with(any_args).and_return false
      allow(msg_handler).to receive(:debug_verbose=).with(any_args)
      allow(msg_handler).to receive(:quiet).with(any_args).and_return false
      allow(msg_handler).to receive(:quiet=).with(any_args)
      allow(msg_handler).to receive(:verbose).with(any_args).and_return false
      allow(msg_handler).to receive(:verbose=).with(any_args)
      expect(::Deepblue::DoiPendingReportTask).to receive(:new).with(options: options).at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once).and_call_original
      expect(::Deepblue::DoiMintingService).to receive(:doi_pending_finder).with( data_set_ids_found: [],
                                                                                  file_set_ids_found: [],
                                                                                  debug_verbose: false,
                                                                                  msg_handler: msg_handler ).at_least(:once).and_call_original
    end

    after do
      Rake::Task["deepblue:doi_pending_report"].reenable
    end

    it "invokes Deepblue::DoiPendingReport" do
      Rake::Task["deepblue:doi_pending_report"].invoke( options )
    end

  end

end