# frozen_string_literal: true

require 'rails_helper'

Rails.application.load_tasks

require_relative '../../app/tasks/deepblue/yaml_populate_for_work'

describe "yaml_populate_for_work.rake" do

  # reference: https://tasdikrahman.me/2020/10/20/testing-rake-tasks-with-rspec/

  context "yaml_populate_from_work" do

    let(:task)    { 'deepblue:yaml_populate_from_work' }
    let(:id)      { 'f4752g72m' }
    let(:options) { { target_dir: "/deepbluedata-prep", export_files:true, mode:"build" } }
    let(:invoked) { ::Deepblue::YamlPopulateFromWork.new( id: id, options: options ) }


    before do
      expect(::Deepblue::YamlPopulateFromWork).to receive(:new)
                                                 .with( any_args )
                                                 .at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once)
    end

    after do
      Rake::Task[task].reenable
    end

    it "invokes Deepblue::YamlPopulateFromWork" do
      Rake::Task[task].invoke( id: id, options: options )
    end

  end

  context "yaml_populate_from_multiple_works" do

    let(:task)    { 'deepblue:yaml_populate_from_multiple_works' }
    let(:ids)     { 'f4752g72m f4752g72m' }
    let(:options) { { target_dir: "/deepbluedata-prep", export_files:true, mode:"build" } }
    let(:invoked) { ::Deepblue::YamlPopulateFromMultipleWorks.new( ids: ids, options: options ) }


    before do
      expect(::Deepblue::YamlPopulateFromMultipleWorks).to receive(:new)
                                                    .with( any_args )
                                                    .at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once)
    end

    after do
      Rake::Task[task].reenable
    end

    it "invokes Deepblue::YamlPopulateFromMultipleWorks" do
      Rake::Task[task].invoke( ids: ids, options: options )
    end

  end

  context "yaml_populate_from_all_works" do

    let(:task)    { 'deepblue:yaml_populate_from_all_works' }
    let(:options) { { target_dir: "/deepbluedata-prep", export_files:true, mode:"build" } }
    let(:invoked) { ::Deepblue::YamlPopulateFromAllWorks.new( options: options ) }


    before do
      expect(::Deepblue::YamlPopulateFromAllWorks).to receive(:new)
                                                             .with( any_args )
                                                             .at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once)
    end

    after do
      Rake::Task[task].reenable
    end

    it "invokes Deepblue::YamlPopulateFromAllWorks" do
      Rake::Task[task].invoke( *options )
    end

  end

end
