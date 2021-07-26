# frozen_string_literal: true

# keywords task_spec

require 'rails_helper'

Rails.application.load_tasks

require_relative '../../lib/tasks/assets_with_expired_embargoes_report_task'

describe "assets_under_embargoe_report_task.rake" do

  # reference: https://tasdikrahman.me/2020/10/20/testing-rake-tasks-with-rspec/

  context "assets_with_expired_embargoes_report" do

    let(:options)  { {} }
    let(:id)       { 'dbdcolid' }
    let(:invoked)  { Deepblue::AssetsWithExpiredEmbargoesReportTask.new( options: options ) }

    before do
      expect( ::Deepblue::AssetsWithExpiredEmbargoesReportTask ).to receive(:new).with( options: options ).at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once)
    end

    after do
      Rake::Task["deepblue:assets_with_expired_embargoes_report"].reenable
    end

    it "invokes Deepblue::AssetsWithExpiredEmbargoesReportTask" do
      Rake::Task["deepblue:assets_with_expired_embargoes_report"].invoke( options )
    end

  end

end