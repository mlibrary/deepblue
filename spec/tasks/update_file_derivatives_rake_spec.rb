# frozen_string_literal: true

require 'rails_helper'

Rails.application.load_tasks

describe "update_file_derivatives.rake" do

  # reference: https://tasdikrahman.me/2020/10/20/testing-rake-tasks-with-rspec/

  context "update_all_work_file_sets" do

    let(:task)    { 'deepblue:update_all_work_file_sets' }
    let(:invoked) { ::Deepblue::UpdateAllWorkFileSets.new }


    before do
      expect(::Deepblue::UpdateAllWorkFileSets).to receive(:new).with( any_args ).at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once)
    end

    after do
      Rake::Task[task].reenable
    end

    it "invokes Deepblue::UpdateAllWorkFileSets" do
      Rake::Task[task].invoke
    end

  end

  context "update_work_file_sets" do

    let(:task)    { 'deepblue:update_work_file_sets' }
    let(:invoked) { ::Deepblue::UpdateWorkFileSets.new }


    before do
      expect(::Deepblue::UpdateWorkFileSets).to receive(:new).with( any_args ).at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once)
    end

    after do
      Rake::Task[task].reenable
    end

    it "invokes Deepblue::UpdateWorkFileSets" do
      Rake::Task[task].invoke
    end

  end

end
