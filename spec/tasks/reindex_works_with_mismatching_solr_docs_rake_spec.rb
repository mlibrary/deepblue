# frozen_string_literal: true

require 'rails_helper'

Rails.application.load_tasks

describe "reindex_works_with_mismatching_solr_docs.rake" do

  # reference: https://tasdikrahman.me/2020/10/20/testing-rake-tasks-with-rspec/

  context "reindex_works_with_mismatching_solr_docs" do

    let(:task)    { 'deepblue:reindex_works_with_mismatching_solr_docs' }
    let(:invoked) { ::Deepblue::ReindexWorksWithMismatchingSolrDocs.new }


    before do
      expect(::Deepblue::ReindexWorksWithMismatchingSolrDocs).to receive(:new).with( any_args ).at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once)
    end

    after do
      Rake::Task[task].reenable
    end

    it "invokes Deepblue::ReindexWorksWithMismatchingSolrDocs" do
      Rake::Task[task].invoke
    end

  end

end
