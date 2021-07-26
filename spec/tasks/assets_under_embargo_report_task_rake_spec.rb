# frozen_string_literal: true

# keywords task_spec

require 'rails_helper'

Rails.application.load_tasks

require_relative '../../lib/tasks/assets_under_embargo_report_task'

describe "assets_under_embargoe_report_task.rake" do

  # reference: https://tasdikrahman.me/2020/10/20/testing-rake-tasks-with-rspec/

  context "assets_under_embargo_report" do

    let(:options)  { {} }
    let(:id)       { 'dbdcolid' }
    let(:invoked)  { Deepblue::AssetsUnderEmbargoReportTask.new( options: options ) }

    before do
      expect( ::Deepblue::AssetsUnderEmbargoReportTask ).to receive(:new).with( options: options ).at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once)
    end

    after do
      Rake::Task["deepblue:assets_under_embargo_report"].reenable
    end

    it "invokes Deepblue::AssetsUnderEmbargoReportTask" do
      Rake::Task["deepblue:assets_under_embargo_report"].invoke( options )
    end

  end

end