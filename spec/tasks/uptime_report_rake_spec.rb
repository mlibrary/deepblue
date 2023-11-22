# frozen_string_literal: true

require 'rails_helper'

Rails.application.load_tasks

describe "uptime_report.rake" do

  # reference: https://tasdikrahman.me/2020/10/20/testing-rake-tasks-with-rspec/

  context "uptime_report" do

    let(:task)    { 'deepblue:uptime_report' }
    let(:options) { {} }
    let(:invoked) { ::Deepblue::UptimeReport.new( options: options ) }


    before do
      expect(::Deepblue::UptimeReport).to receive(:new)
                                                        .with( options: options )
                                                        .at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once)
    end

    after do
      Rake::Task[task].reenable
    end

    it "invokes Deepblue::UptimeReport" do
      Rake::Task[task].invoke( options )
    end

  end

end
