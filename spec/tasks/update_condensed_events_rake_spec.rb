# frozen_string_literal: true

require 'rails_helper'

Rails.application.load_tasks

describe "update_condensed_events.rake" do

  # reference: https://tasdikrahman.me/2020/10/20/testing-rake-tasks-with-rspec/

  context "update_condensed_events" do

    let(:task)    { 'deepblue:update_condensed_events' }
    let(:invoked) { ::Deepblue::UpdateCondensedEventsTask.new( options: {} ) }


    before do
      expect(::Deepblue::UpdateCondensedEventsTask).to receive(:new).with( any_args ).at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once)
    end

    after do
      Rake::Task[task].reenable
    end

    it "invokes Deepblue::UpdateCondensedEventsTask" do
      Rake::Task[task].invoke( options: {} )
    end

  end

end
