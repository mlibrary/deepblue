# frozen_string_literal: true

require 'rails_helper'

Rails.application.load_tasks

describe "work_find_and_fix.rake" do

  # reference: https://tasdikrahman.me/2020/10/20/testing-rake-tasks-with-rspec/

  context "work_find_and_fix" do

    let(:task)     { 'deepblue:work_find_and_fix' }
    let(:options)  { { option: 'an option' } }
    let(:id)       { 'dbdworkid' }
    let(:invoked)  { ::Deepblue::WorkFindAndFixTask.new( id: id, options: options ) }

    before do
      expect(::Deepblue::WorkFindAndFixTask).to receive(:new).with( id: id,
                                                                    options: options ).at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once)
    end

    after do
      Rake::Task[task].reenable
    end

    it "invokes Deepblue::WorkFindAndFixTask" do
      Rake::Task[task].invoke( id, options )
    end

  end

end
