# frozen_string_literal: true

require 'rails_helper'

Rails.application.load_tasks

describe "works_and_files_missing_solr_docs.rake" do

  # reference: https://tasdikrahman.me/2020/10/20/testing-rake-tasks-with-rspec/

  context "works_and_files_missing_solr_docs" do

    let(:task)    { 'deepblue:works_and_files_missing_solr_docs' }
    let(:options) { {} }
    let(:invoked) { ::Deepblue::WorksAndFilesMissingSolrdocs.new( options: options ) }


    before do
      expect(::Deepblue::WorksAndFilesMissingSolrdocs).to receive(:new)
                                                        .with( options: options )
                                                        .at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once)
    end

    after do
      Rake::Task[task].reenable
    end

    it "invokes Deepblue::WorksAndFilesMissingSolrdocs" do
      Rake::Task[task].invoke( options )
    end

  end

end
