# frozen_string_literal: true

# keywords task_spec

require 'rails_helper'

Rails.application.load_tasks

require_relative '../../app/services/deepblue/work_view_content_service'
require_relative '../../lib/tasks/yaml_populate_for_collection'

describe "export_documentation.rake" do

  # reference: https://tasdikrahman.me/2020/10/20/testing-rake-tasks-with-rspec/

  context "export_documentation" do

    let(:options)  { {} }
    let(:id)       { 'dbdcolid' }
    let(:invoked)  { Deepblue::YamlPopulateFromCollection.new( id: id, options: options ) }

    before do
      expect(::Deepblue::WorkViewContentService).to receive(:content_documentation_collection_id).and_return id
      expect( ::Deepblue::YamlPopulateFromCollection ).to receive(:new).with( id: id,
                                                                              options: options ).at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once)
    end

    after do
      Rake::Task["deepblue:export_documentation"].reenable
    end

    it "invokes Deepblue::YamlPopulateFromCollection" do
      Rake::Task["deepblue:export_documentation"].invoke( options )
    end

  end

end