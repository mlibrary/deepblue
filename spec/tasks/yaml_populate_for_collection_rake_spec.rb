# frozen_string_literal: true

# keywords task_spec

require 'rails_helper'

Rails.application.load_tasks

require_relative '../../app/tasks/deepblue/yaml_populate_for_collection'

describe "yaml_populate_for_collection.rake" do

  # reference: https://tasdikrahman.me/2020/10/20/testing-rake-tasks-with-rspec/

  context "yaml_populate_from_collection" do

    let(:options)  { {} }
    let(:id)       { 'id123' }
    let(:invoked)  { Deepblue::YamlPopulateFromCollection.new( id: id, options: options ) }
    # let(:service)  { double(::Deepblue::YamlPopulateService) }

    before do
      expect( ::Deepblue::YamlPopulateFromCollection ).to receive(:new).with( id: id,
                                                                              options: options ).at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once)
      # expect(::Deepblue::YamlPopulateService).to receive(:new).with( mode: 'build',
      #                                                                create_zero_length_files: true,
      #                                                                overwrite_export_files: true ).and_return service
      # expect(service).to receive(:yaml_populate_collection).with({:collection=>"id123 id234",
      #                                                             :dir=>"/deepbluedata-prep",
      #                                                             :export_files=>true})
      # expect(service).to receive(:yaml_populate_stats).and_return 'stats'
      # expect(invoked).to receive(:report_stats).once
    end

    after do
      Rake::Task["deepblue:yaml_populate_from_collection"].reenable
    end

    it "invokes Deepblue::YamlPopulateFromCollection" do
      Rake::Task["deepblue:yaml_populate_from_collection"].invoke( id, options )
    end

  end

  context "yaml_populate_from_collection", skip: false do

    let(:options)  { {} }
    let(:ids)      { 'id123 id234' }
    let(:invoked)  { Deepblue::YamlPopulateFromMultipleCollections.new( ids: ids, options: options ) }

    before do
      expect( ::Deepblue::YamlPopulateFromMultipleCollections ).to receive(:new).with( ids: ids,
                                                                                       options: options ).at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once)
    end

    after do
      Rake::Task["deepblue:yaml_populate_from_multiple_collections"].reenable
    end

    it "invokes Deepblue::YamlPopulateFromMultipleCollections" do
      Rake::Task["deepblue:yaml_populate_from_multiple_collections"].invoke( ids, options )
    end

  end

  context "yaml_populate_from_all_collections", skip: false do

    let(:options)  { {} }
    let(:invoked)  { Deepblue::YamlPopulateFromAllCollections.new( options: options ) }

    before do
      expect( ::Deepblue::YamlPopulateFromAllCollections ).to receive(:new).with( options: options ).at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once)
    end

    after do
      Rake::Task["deepblue:yaml_populate_from_all_collections"].reenable
    end

    it "invokes Deepblue::YamlPopulateFromMultipleCollections" do
      Rake::Task["deepblue:yaml_populate_from_all_collections"].invoke( options )
    end

  end

end
