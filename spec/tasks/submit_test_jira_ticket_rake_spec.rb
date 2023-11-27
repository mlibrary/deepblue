# frozen_string_literal: true

require 'rails_helper'

Rails.application.load_tasks

describe "submit_test_jira_ticket.rake" do

  # reference: https://tasdikrahman.me/2020/10/20/testing-rake-tasks-with-rspec/

  context "submit_test_jira_ticket" do

    let(:task)    { 'deepblue:submit_test_jira_ticket' }
    let(:invoked) { ::Deepblue::SubmitTestJiraTicket.new( options: {} ) }


    before do
      expect(::Deepblue::SubmitTestJiraTicket).to receive(:new).with( any_args ).at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once)
    end

    after do
      Rake::Task[task].reenable
    end

    it "invokes Deepblue::SubmitTestJiraTicket" do
      Rake::Task[task].invoke( options: {} )
    end

  end

end
