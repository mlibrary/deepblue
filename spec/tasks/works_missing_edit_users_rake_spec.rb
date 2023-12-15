# frozen_string_literal: true

require 'rails_helper'

Rails.application.load_tasks

describe "works_missing_edit_users.rake" do

  # reference: https://tasdikrahman.me/2020/10/20/testing-rake-tasks-with-rspec/

  context "works_missing_edit_users" do

    let(:task)    { 'deepblue:works_missing_edit_users' }
    let(:invoked) { ::Deepblue::WorksMissingEditUsers.new }


    before do
      expect(::Deepblue::WorksMissingEditUsers).to receive(:new)
                                                        .with( any_args )
                                                        .at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once)
      # expect(invoked).to receive(:logger).with(any_args).at_least(:once)
    end

    after do
      Rake::Task[task].reenable
    end

    it "invokes Deepblue::WorksMissingEditUsers" do
      task1 = Rake::Task[task]
      puts "task1=#{task1}"
      puts "task1.class=#{task1.class}"
      task1.invoke
    end

  end

end
