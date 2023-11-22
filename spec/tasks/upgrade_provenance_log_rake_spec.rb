# frozen_string_literal: true

require 'rails_helper'

Rails.application.load_tasks

describe "upgrade_provenance_log.rake" do

  # reference: https://tasdikrahman.me/2020/10/20/testing-rake-tasks-with-rspec/

  context "upgrade_provenance_log" do

    let(:task)    { 'deepblue:upgrade_provenance_log' }
    let(:invoked) { ::Deepblue::UpgradeProvenanceLog.new( input_file: nil,
                                                          output_file: 'file2',
                                                          report_file: 'file3' ) }


    before do
      expect(::Deepblue::UpgradeProvenanceLog).to receive(:new)
                                                        .with( any_args )
                                                        .at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once)
    end

    after do
      Rake::Task[task].reenable
    end

    it "invokes Deepblue::UpgradeProvenanceLog" do
      Rake::Task[task].invoke( input_file: nil,
                               output_file: 'file2',
                               report_file: 'file3' )
    end

  end

end
