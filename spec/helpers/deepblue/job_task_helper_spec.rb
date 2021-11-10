# frozen_string_literal: true

require 'rails_helper'

class MockJobForJobTaskHelper < ::Hyrax::ApplicationJob

    include JobHelper

    attr_accessor :hostnames,
                  :job_delay,
                  :options,
                  :subscription_service_id,
                  :timestamp_begin,
                  :timestamp_end,
                  :verbose

end

RSpec.describe Deepblue::JobTaskHelper, type: :helper do

  let(:job) { MockJobForJobTaskHelper.new }
  let(:hostname_allowed) { [::DeepBlueDocs::Application.config.hostname] }

  before do
    allow( job ).to receive(:verbose).and_return false
  end

  describe 'module debug verbose variables' do
    it { expect( described_class.job_task_helper_debug_verbose                  ).to eq false }
    it { expect( described_class.run_job_task_debug_verbose                     ).to eq false }
    it { expect( described_class.about_to_expire_embargoes_job_debug_verbose    ).to eq false }
    it { expect( described_class.abstract_rake_task_job_debug_verbose           ).to eq false }
    it { expect( described_class.deactivate_expired_embargoes_job_debug_verbose ).to eq false }
    it { expect( described_class.heartbeat_job_debug_verbose                    ).to eq false }
    it { expect( described_class.heartbeat_email_job_debug_verbose              ).to eq false }
    it { expect( described_class.monthly_analytics_report_job_debug_verbose     ).to eq false }
    it { expect( described_class.monthly_events_report_job_debug_verbose        ).to eq false }
    it { expect( described_class.rake_task_job_debug_verbose                    ).to eq false }
    it { expect( described_class.run_job_task_debug_verbose                     ).to eq false }
    it { expect( described_class.scheduler_start_job_debug_verbose              ).to eq false }
    it { expect( described_class.update_condensed_events_job_debug_verbose      ).to eq false }
    it { expect( described_class.user_stat_importer_job_debug_verbose           ).to eq false }
    it { expect( described_class.works_report_job_debug_verbose                 ).to eq false }
  end

  describe 'module variables' do
    it "they have the right values" do
      expect( described_class.allowed_job_tasks ).to eq( [ "-T", "tmp:clear" ] )
    end
  end

  describe '.hostname' do
    subject { described_class.hostname }
    it { expect( subject ).to eq( ::DeepBlueDocs::Application.config.hostname ) }
  end

  describe '.hostname_allowed' do
    let(:task) { false }

    context 'when hostname not allowed' do
      let(:hostnames) { [] }
      let(:options)   { { 'hostnames' => hostnames, 'quiet' => true } }
      subject { described_class.hostname_allowed( job: job ) }
      before do
        expect( job ).to receive( :options ).and_return options
        expect( job ).to receive( :job_options_value ).with( options,
                                                             key: 'hostnames',
                                                             default_value: [],
                                                             verbose: false,
                                                             task: task ).and_call_original
      end
      it { expect( subject ).to eq( false ) }
    end

    context 'when hostname allowed' do
      let(:hostnames) { [::DeepBlueDocs::Application.config.hostname] }
      let(:options)   { { 'hostnames' => hostnames, 'quiet' => true } }
      subject { described_class.hostname_allowed( job: job ) }
      before do
        expect( job ).to receive( :options ).and_return options
        expect( job ).to receive( :job_options_value ).with( options,
                                                             key: 'hostnames',
                                                             default_value: [],
                                                             verbose: false,
                                                             task: task ).and_call_original
      end
      it { expect( subject ).to eq( true ) }
    end

  end

end
