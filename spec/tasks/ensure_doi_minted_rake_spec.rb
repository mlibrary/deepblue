# frozen_string_literal: true

# keywords task_spec

require 'rails_helper'

Rails.application.load_tasks

require_relative '../../lib/tasks/ensure_doi_minted_task'

describe "ensure_doi_minted_task.rake" do

  # reference: https://tasdikrahman.me/2020/10/20/testing-rake-tasks-with-rspec/

  context "work_find_and_fix" do

    let(:options)  { { option: 'an option' } }
    let(:id)       { 'dbdworkid' }
    let(:invoked)  { ::Deepblue::EnsureDoiMintedTask.new( id: id, options: options ) }

    before do
      expect(::Deepblue::EnsureDoiMintedTask).to receive(:new).with( id: id,
                                                                    options: options ).at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once)
    end

    after do
      Rake::Task["deepblue:ensure_doi_minted"].reenable
    end

    it "invokes Deepblue::EnsureDoiMintedTask" do
      Rake::Task["deepblue:ensure_doi_minted"].invoke( id, options )
    end

  end

end
