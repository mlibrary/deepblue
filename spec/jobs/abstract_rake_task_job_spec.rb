# frozen_string_literal: true

require 'rails_helper'

class MockJobForAbstractRakeTaskJob < AbstractRakeTaskJob

end

RSpec.describe AbstractRakeTaskJob, skip: false do

  let(:job) { MockJobForAbstractRakeTaskJob.new }
  let(:hostname_allowed) { [::DeepBlueDocs::Application.config.hostname] }

  before do
    allow( job ).to receive(:verbose).and_return false
  end

  describe 'module debug verbose variables' do
    it "they have the right values" do
      expect( described_class.abstract_rake_task_job_debug_verbose ).to eq( false )
    end
  end

end
