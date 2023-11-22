# frozen_string_literal: true

require 'rails_helper'

Rails.application.load_tasks

describe "works_with_mismatching_solr_docs.rake" do

  # reference: https://tasdikrahman.me/2020/10/20/testing-rake-tasks-with-rspec/

  context "works_with_mismatching_solr_docs" do

    let(:task)    { 'deepblue:works_with_mismatching_solr_docs' }
    let(:invoked) { ::Deepblue::WorksWithMismatchingSolrDocs.new }


    before do
      expect(::Deepblue::WorksWithMismatchingSolrDocs).to receive(:new)
                                                        .with( no_args )
                                                        .at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once)
    end

    after do
      Rake::Task[task].reenable
    end

    it "invokes Deepblue::WorksWithMismatchingSolrDocs" do
      Rake::Task[task].invoke
    end

  end

end
