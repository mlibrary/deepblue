# frozen_string_literal: true

require 'rails_helper'

Rails.application.load_tasks

describe "work_impact_report.rake" do

  # reference: https://tasdikrahman.me/2020/10/20/testing-rake-tasks-with-rspec/

  context "work_impact_report" do

    let(:task)    { 'deepblue:work_impact_report' }
    let(:options) { {} }
    let(:invoked) { ::Deepblue::WorkImpactReporter.new( options: options ) }


    before do
      expect(::Deepblue::WorkImpactReporter).to receive(:new)
                                                        .with( any_args )
                                                        .at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once)
    end

    after do
      Rake::Task[task].reenable
    end

    it "invokes Deepblue::WorkImpactReporter" do
      Rake::Task[task].invoke( options )
    end

  end

end
