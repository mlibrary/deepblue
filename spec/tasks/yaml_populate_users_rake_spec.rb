# frozen_string_literal: true

require 'rails_helper'

Rails.application.load_tasks

describe "yaml_populate_users.rake" do

  # reference: https://tasdikrahman.me/2020/10/20/testing-rake-tasks-with-rspec/

  context "yaml_populate_users" do

    let(:task)    { 'deepblue:yaml_populate_users' }
    let(:options) { { target_dir: "/deepbluedata-prep", mode: "migrate" } }
    let(:invoked) { ::Deepblue::YamlPopulateUsers.new( options: options ) }


    before do
      expect(::Deepblue::YamlPopulateUsers).to receive(:new)
                                                        .with( options: options )
                                                        .at_least(:once).and_return invoked
      expect(invoked).to receive(:run).with(no_args).at_least(:once)
    end

    after do
      Rake::Task[task].reenable
    end

    it "invokes Deepblue::YamlPopulateUsers" do
      Rake::Task[task].invoke( options )
    end

  end

end
