# frozen_string_literal: true

require 'rails_helper'

Rails.application.load_tasks

describe "works_and_files_missing_edit_users.rake" do

  # reference: https://tasdikrahman.me/2020/10/20/testing-rake-tasks-with-rspec/

  context "works_and_files_missing_edit_users" do

    let(:task)    { 'deepblue:works_and_files_missing_edit_users' }
    let(:options) { {} }
    let(:invoked) { ::Deepblue::WorksAndFilesMissingEditUsers.new( options: options ) }


    before do
      expect(::Deepblue::WorksAndFilesMissingEditUsers).to receive(:new)
                                                        .with( options: options )
                                                        .at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once)
    end

    after do
      Rake::Task[task].reenable
    end

    it "invokes Deepblue::WorksAndFilesMissingEditUsers" do
      Rake::Task[task].invoke( options )
    end

  end

end
