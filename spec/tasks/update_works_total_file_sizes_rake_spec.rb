# frozen_string_literal: true

require 'rails_helper'

Rails.application.load_tasks

describe "update_works_total_file_sizes.rake" do

  # reference: https://tasdikrahman.me/2020/10/20/testing-rake-tasks-with-rspec/

  context "update_works" do

    let(:task)    { 'deepblue:update_works' }
    let(:invoked) { ::Deepblue::UpdateWorks.new }


    before do
      expect(::Deepblue::UpdateWorks).to receive(:new).with( any_args ).at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once)
    end

    after do
      Rake::Task[task].reenable
    end

    it "invokes Deepblue::UpdateWorks" do
      Rake::Task[task].invoke
    end

  end

  context "update_work" do

    let(:task)    { 'deepblue:update_work' }
    let(:invoked) { ::Deepblue::UpdateWork.new }


    before do
      expect(::Deepblue::UpdateWork).to receive(:new).with( any_args ).at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once)
    end

    after do
      Rake::Task[task].reenable
    end

    it "invokes Deepblue::UpdateWork" do
      Rake::Task[task].invoke
    end

  end

end
