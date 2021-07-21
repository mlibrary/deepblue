# frozen_string_literal: true

# keywords task_spec

require 'rails_helper'

Rails.application.load_tasks

# require_relative '../../app/services/deepblue/work_view_content_service'
require_relative '../../lib/tasks/about_to_expire_embargoes_task'

describe "about_to_expire_embargoes_task.rake" do

  # reference: https://tasdikrahman.me/2020/10/20/testing-rake-tasks-with-rspec/

  context "about_to_expire_embargoes_task" do

    let(:options)  { {} }
    let(:id)       { 'dbdcolid' }
    let(:invoked)  { Deepblue::AboutToExpireEmbargoesTask.new( options: options ) }

    before do
      allow(::Deepblue::WorkViewContentService).to receive(:content_documentation_collection_id).and_return id
      expect( ::Deepblue::AboutToExpireEmbargoesTask ).to receive(:new).with( options: options ).at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once)
    end

    after do
      Rake::Task["deepblue:about_to_expire_embargoes"].reenable
    end

    it "invokes Deepblue::AboutToExpireEmbargoesTask" do
      Rake::Task["deepblue:about_to_expire_embargoes"].invoke( options )
    end

  end

end