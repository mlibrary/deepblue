# frozen_string_literal: true

# keywords task_spec

require 'rails_helper'

Rails.application.load_tasks

require_relative '../../lib/tasks/clean_blacklight_query_cache_task'

describe "clean_blacklight_query_cache.rake" do

  # reference: https://tasdikrahman.me/2020/10/20/testing-rake-tasks-with-rspec/

  context "clean_blacklight_query_cache_task" do

    let(:options)  { { option: 'an option' } }
    let(:invoked)  { ::Deepblue::CleanBlacklightQueryCacheTask.new( options: options ) }

    before do
      expect(::Deepblue::CleanBlacklightQueryCacheTask).to receive(:new).with( options: options ).at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once)
    end

    after do
      Rake::Task["deepblue:clean_blacklight_query_cache"].reenable
    end

    it "invokes Deepblue::ExportLogFilesTask" do
      Rake::Task["deepblue:clean_blacklight_query_cache"].invoke( options )
    end

  end

end
