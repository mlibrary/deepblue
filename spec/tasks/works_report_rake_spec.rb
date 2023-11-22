# frozen_string_literal: true

require 'rails_helper'
require_relative '../../app/services/deepblue/works_reporter'

Rails.application.load_tasks

describe "works_report.rake" do

  # reference: https://tasdikrahman.me/2020/10/20/testing-rake-tasks-with-rspec/

  context "works_report" do

    let(:task)    { 'deepblue:works_report' }
    let(:invoked) { ::Deepblue::WorksReporter.new }


    before do
      expect(::Deepblue::WorksReporter).to receive(:new).with(any_args).at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once)
    end

    after do
      Rake::Task[task].reenable
    end

    it "invokes Deepblue::WorksReporter" do
      Rake::Task[task].invoke()
    end

  end

end
