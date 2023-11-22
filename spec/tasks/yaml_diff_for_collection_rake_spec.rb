# frozen_string_literal: true

require 'rails_helper'

Rails.application.load_tasks

describe "yaml_diff_for_collections.rake" do

  # reference: https://tasdikrahman.me/2020/10/20/testing-rake-tasks-with-rspec/

  context "yaml_diff_for_collections" do

    let(:task)    { 'deepblue:yaml_diff_for_collections' }
    let(:options) { { source_dir: "/deepbluedata-prep", ingester: "ingester@umich.edu" } }
    let(:ids)     { 'f4752g72m f4752g72m' }
    let(:invoked) { ::Deepblue::YamlDiffForCollections.new( ids: ids, options: options ) }


    before do
      expect(::Deepblue::YamlDiffForCollections).to receive(:new)
                                                        .with( ids: ids, options: options )
                                                        .at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once)
    end

    after do
      Rake::Task[task].reenable
    end

    it "invokes Deepblue::YamlDiffForCollections" do
      Rake::Task[task].invoke( ids, options )
    end

  end

end
