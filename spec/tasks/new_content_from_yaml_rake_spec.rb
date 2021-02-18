# frozen_string_literal: true

# keywords task_spec

require 'rails_helper'

Rails.application.load_tasks

describe "new_content_from_yaml task" do

  # reference: https://tasdikrahman.me/2020/10/20/testing-rake-tasks-with-rspec/

  # after(:each) do
  #   Rake::Task["task:user_stats_import"].reenable
  # end

  context "user_stats_import Deepblue" do

    let(:base_file_names) { 'f4752g72m g4752g72m' }
    # NOTE: have to remove backslashes using .gsub(/\\,/,',')
    let(:options) { '{"source_dir":"/deepbluedata-prep"\,"mode":"build"\,"prefix":""\,"postfix":"_populate"\,"ingester":"ingester@umich.edu"}'.gsub(/\\,/,',') }
    let(:importer) { Deepblue::NewContentFromYaml.new(base_file_names: base_file_names, options: options) }

    before do
      expect( Deepblue::NewContentFromYaml ).to receive(:new).with(base_file_names: base_file_names,
                                                                   options: options).at_least(:once).and_return importer
      expect(importer).to receive(:run).with(no_args)
    end


    after do
      Rake::Task["deepblue:new_content_from_yaml"].reenable
    end

    it "invokes Deepblue::UserStatImporter" do
      Rake::Task["deepblue:new_content_from_yaml"].invoke(base_file_names, options)
    end

  end

end