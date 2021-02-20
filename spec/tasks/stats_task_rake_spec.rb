# frozen_string_literal: true

# keywords task_spec

require 'rails_helper'

Rails.application.load_tasks

require_relative '../../app/services/hyrax/user_stat_importer.rb'

describe "stat_task" do

  # reference: https://tasdikrahman.me/2020/10/20/testing-rake-tasks-with-rspec/

  # after(:each) do
  #   Rake::Task["task:user_stats_import"].reenable
  # end

  context "user_stats_import Deepblue" do

    let(:options) { {} }
    let(:importer) { Deepblue::UserStatImporter.new(options: options) }

    before do
      expect( Deepblue::UserStatImporter ).to receive(:new).with(options: options).at_least(:once).and_return importer
      expect(importer).to receive(:run).with(no_args).at_least(:once)
    end

    after do
      Rake::Task["deepblue:user_stats_import"].reenable
    end

    it "invokes Deepblue::UserStatImporter" do
      Rake::Task["deepblue:user_stats_import"].invoke(options)
    end

  end

  context "user_stats_import Hyrax" do

    let(:options) { {} }
    let(:importer) { Hyrax::UserStatImporter.new(verbose: true, logging: true) }

    before do
      expect( Hyrax::UserStatImporter ).to receive(:new).with(verbose: true, logging: true).at_least(:once).and_return importer
      expect(importer).to receive(:import).with(no_args).at_least(:once)
    end

    after do
      Rake::Task["hyrax:stats:user_stats"].reenable
    end

    it "invokes Hyrax::UserStatImporter" do
      Rake::Task["hyrax:stats:user_stats"].invoke
    end

  end

end