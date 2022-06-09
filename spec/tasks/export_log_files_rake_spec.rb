# frozen_string_literal: true

# keywords task_spec

require 'rails_helper'

Rails.application.load_tasks

require_relative '../../lib/tasks/export_log_files_task'

describe "export_log_files_task.rake" do

  # reference: https://tasdikrahman.me/2020/10/20/testing-rake-tasks-with-rspec/

  context "export_log_files_task" do

    let(:options)  { { option: 'an option' } }
    let(:invoked)  { ::Deepblue::ExportLogFilesTask.new( options: options ) }

    before do
      expect(::Deepblue::ExportLogFilesTask).to receive(:new).with( options: options ).at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once)
    end

    after do
      Rake::Task["deepblue:export_log_files"].reenable
    end

    it "invokes Deepblue::ExportLogFilesTask" do
      Rake::Task["deepblue:export_log_files"].invoke( options )
    end

  end

end
