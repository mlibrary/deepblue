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
  let(:hostname_allowed) { [Rails.configuration.hostname] }

  before do
    allow( job ).to receive(:verbose).and_return false
  end

  describe 'module debug verbose variables' do
    it { expect( described_class.job_task_helper_debug_verbose                  ).to eq false }

    it { expect( described_class.about_to_expire_embargoes_job_debug_verbose    ).to eq false }
    it { expect( described_class.abstract_rake_task_job_debug_verbose           ).to eq false }
    it { expect( described_class.deactivate_expired_embargoes_job_debug_verbose ).to eq false }
    it { expect( described_class.deepblue_job_debug_verbose                     ).to eq false }
    it { expect( described_class.export_documentation_job_debug_verbose         ).to eq false }
    it { expect( described_class.fedora_accessible_job_debug_verbose            ).to eq false }
    it { expect( described_class.globus_errors_report_job_debug_verbose         ).to eq false }
    it { expect( described_class.globus_status_report_job_debug_verbose         ).to eq false }
    it { expect( described_class.heartbeat_email_job_debug_verbose              ).to eq false }
    it { expect( described_class.heartbeat_job_debug_verbose                    ).to eq false }
    it { expect( described_class.jira_new_ticket_job_debug_verbose              ).to eq false }
    it { expect( described_class.job_helper_debug_verbose                       ).to eq false }
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
    it { expect( described_class.allowed_job_tasks ).to eq( [ '-T', 'tmp:clean' ] ) }
    it { expect( described_class.allowed_job_task_matching ).to eq( [ /blacklight:delete_old_searches\[\d+\]/ ] ) }
    it { expect( described_class.job_failure_email_subscribers ).to eq( [ 'fritx@umich.edu' ] ) }
  end

  describe '.hostname' do
    subject { described_class.hostname }
    it { expect( subject ).to eq( Rails.configuration.hostname ) }
  end

  describe '.hostname_allowed' do
    let(:task) { false }

    context 'when hostname not allowed' do
      let(:hostnames) { [] }
      let(:options)   { { 'hostnames' => hostnames, 'quiet' => true } }
      subject { described_class.hostname_allowed( job: job, options: options ) }
      before do
        #expect( job ).to receive( :options ).and_return options
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
      subject { described_class.hostname_allowed( job: job, options: options ) }
      before do
        #expect( job ).to receive( :options ).and_return options
        expect( job ).to receive( :job_options_value ).with( options,
                                                             key: 'hostnames',
                                                             default_value: [],
                                                             verbose: false,
                                                             task: task ).and_call_original
      end
      it { expect( subject ).to eq( true ) }
    end

  end

  describe '.normalize_args' do

    context 'when a hash' do
      let(:args) { {x: 'y'} }
      let(:args2) { {x: 'y', a: 'b'} }
      it { expect( described_class.normalize_args(*args) ).to eq( [[:x,'y']] ) }
      it { expect( described_class.normalize_args(*args2) ).to eq( [[:x,'y'],[:a,'b']] ) }
    end

    context 'when an array contains an array contains a hash' do
      let(:hash) { {x: 'y'} }
      let(:hash2) { {x: 'y', a: 'b'} }
      let(:array) { [[:x, 'y']] }
      let(:array2) { [[:x, 'y'], [:a, 'b']] }
      # let(:args) { [array] }
      # let(:args2) { [[array]] }
      # let(:args3) { [array2] }
      # let(:args4) { [[array2]] }
      it { expect( described_class.normalize_args(*hash) ).to eq( array ) }
      it { expect( described_class.normalize_args(*hash2) ).to eq( array2 ) }
      # it { expect( described_class.normalize_args(*args3) ).to eq( hash2 ) }
      # it { expect( described_class.normalize_args(*args4) ).to eq( hash2 ) }
    end

    # context 'when an array containing an array that looks like a hash' do
    #   let(:array) { [:x, 'y'] }
    #   let(:array2) { [:x, 'y', :a, 'b'] }
    #   let(:args) { [array] }
    #   let(:args2) { [[array]] }
    #   let(:args3) { [array2] }
    #   let(:args4) { [[array2]] }
    #   it { expect( described_class.normalize_args(*args) ).to eq( array ) }
    #   it { expect( described_class.normalize_args(*args2) ).to eq( array ) }
    #   it { expect( described_class.normalize_args(*args3) ).to eq( array2 ) }
    #   it { expect( described_class.normalize_args(*args4) ).to eq( array2 ) }
    # end

  end

  describe '.initialize_options_from' do
    let(:debug_verbose) { false }
    let(:args) { {x: 'y'} }
    let(:args2) { {x: 'y', a: 'b'} }
    let(:init) { [:x,'y'] }
    let(:init2) { [[:x,'y'],[:a,'b']] }

    context 'it returns options to the correct values 1' do
      it 'does it' do
        expect(::Deepblue::JobTaskHelper).to receive(:normalize_args).with([:x,'y'], debug_verbose: debug_verbose).and_call_original
        expect( described_class.initialize_options_from(*args, debug_verbose: debug_verbose) ).to eq( args.with_indifferent_access )
      end
    end

    context 'it returns options to the correct values 2' do
      it 'does it' do
        expect(::Deepblue::JobTaskHelper).to receive(:normalize_args).with([:x,'y'], [:a,'b'], debug_verbose: debug_verbose).and_call_original
        expect( described_class.initialize_options_from(*args2, debug_verbose: debug_verbose) ).to eq( args2.with_indifferent_access )
      end
    end

  end

end
