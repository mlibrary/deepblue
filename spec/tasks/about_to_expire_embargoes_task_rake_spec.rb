# frozen_string_literal: true

# keywords task_spec

require 'rails_helper'

Rails.application.load_tasks

require_relative '../../lib/tasks/about_to_expire_embargoes_task'
require_relative '../../app/services/deepblue/about_to_expire_embargoes_service'

describe "about_to_expire_embargoes_task.rake" do

  # reference: https://tasdikrahman.me/2020/10/20/testing-rake-tasks-with-rspec/

  context "about_to_expire_embargoes_task" do

    let(:options)  { {} }
    let(:id)       { 'dbdcolid' }
    let(:invoked)  { ::Deepblue::AboutToExpireEmbargoesTask.new( options: options ) }
    let(:service)  { ::Deepblue::AboutToExpireEmbargoesService.allocate }

    before do
      # allow(::Deepblue::WorkViewContentService).to receive(:content_documentation_collection_id).and_return id
      expect( ::Deepblue::AboutToExpireEmbargoesTask ).to receive(:new)
                                                            .with( options: options ).at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once).and_call_original
      expect(::Deepblue::AboutToExpireEmbargoesService).to receive(:new).with( email_owner: true,
                                          expiration_lead_days: nil,
                                          skip_file_sets: true,
                                          test_mode: false,
                                          to_console: true,
                                          verbose: false ).at_least(:once).and_return service
      expect(service).to receive(:run).at_least(:once)
    end

    after do
      Rake::Task["deepblue:about_to_expire_embargoes"].reenable
    end

    it "invokes Deepblue::AboutToExpireEmbargoesTask" do
      Rake::Task["deepblue:about_to_expire_embargoes"].invoke( options )
    end

  end

end