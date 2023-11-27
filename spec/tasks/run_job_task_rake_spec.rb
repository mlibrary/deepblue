# frozen_string_literal: true

require 'rails_helper'

Rails.application.load_tasks

describe "run_job_task.rake" do

  # reference: https://tasdikrahman.me/2020/10/20/testing-rake-tasks-with-rspec/

  context "run_job" do

    let(:task)    { 'deepblue:run_job' }
    let(:invoked) { ::Deepblue::RunJobTask.new( options: {} ) }


    before do
      expect(::Deepblue::RunJobTask).to receive(:new).with( any_args ).at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once)
    end

    after do
      Rake::Task[task].reenable
    end

    it "invokes Deepblue::RunJobTask" do
      Rake::Task[task].invoke( options: {} )
    end

  end

end
