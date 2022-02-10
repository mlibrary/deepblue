# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdateCondensedEventsJob, skip: false do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.update_condensed_events_job_debug_verbose ).to eq( debug_verbose ) }
  end

  let(:analytics_helper) { class_double( AnalyticsHelper ).as_stubbed_const(:transfer_nested_constants => true) }
  let(:sched_helper) { class_double( Deepblue::SchedulerHelper ).as_stubbed_const(:transfer_nested_constants => true) }
  # let(:job_task_helper) { class_double( Deepblue::JobTaskHelper ).as_stubbed_const(:transfer_nested_constants => true) }

  describe 'defines scheduler entry' do
    it 'has scheduler entry' do
      expect( described_class::SCHEDULER_ENTRY ).to include( "class: #{described_class.name}" )
    end
  end

  describe 'all', skip: false do
    RSpec.shared_examples 'shared all' do |run_on_server, dbg_verbose|
      subject { described_class }
      before do
        described_class.update_condensed_events_job_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose
      end
      after do
        described_class.update_condensed_events_job_debug_verbose = debug_verbose
      end
      context do

        context 'with valid arguments' do
          let(:job)       { described_class.send( :job_or_instantiate, *args ) }
          let(:task)      { false }
          let(:verbose)   { false }

          before do
            # TODO: reactivate this
            # expect(sched_helper).to receive(:log).with( class_name: described_class.name,
            #                                             event: "update condensed events job" )
            allow(sched_helper).to receive(:log)
            allow(sched_helper).to receive(:scheduler_log_echo_to_rails_logger).and_return false
            if run_on_server
              expect( analytics_helper ).to receive(:update_current_month_condensed_events)
              expect( analytics_helper ).to receive(:updated_condensed_event_downloads).with( any_args )
            else
              expect( analytics_helper ).to_not receive(:update_current_month_condensed_events)
              expect( analytics_helper ).to_not receive(:updated_condensed_event_downloads).with( any_args )
            end
            allow( job ).to receive(:job_options_value).with( any_args ).and_call_original
          end

          it 'calls update_current_month_condensed_events and updated_condensed_event_downloads' do
            ActiveJob::Base.queue_adapter = :test
            job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
          end
        end

        # context 'without valid hostnames' do
        #   let(:job)       { described_class.send( :job_or_instantiate, *args ) }
        #   let(:hostnames) { [  ] }
        #   let(:args)      { { hostnames: hostnames, quiet: true } }
        #   let(:options)   { { 'hostnames' => hostnames, 'quiet' => true } }
        #   let(:task)      { false }
        #
        #   before do
        #     # TODO: reactivate this
        #     # expect(sched_helper).to receive(:log).with( class_name: described_class.name,
        #     #                                             event: "update condensed events job" )
        #     allow(sched_helper).to receive(:log)
        #     allow(sched_helper).to receive(:scheduler_log_echo_to_rails_logger).and_return false
        #     expect( analytics_helper ).to_not receive(:update_current_month_condensed_events)
        #     allow( job ).to receive(:job_options_value).with( any_args ).and_call_original
        #   end
        #
        #   it 'does not call update_current_month_condensed_events and updated_condensed_event_downloads' do
        #     ActiveJob::Base.queue_adapter = :test
        #     job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
        #   end
        # end

      end
    end

    context 'with valid hostname' do
      let(:hostnames) { build(:hostnames_allowed) }
      let(:args)      { { hostnames: hostnames, quiet: true } }
      let(:options)   { args.with_indifferent_access }
      # let(:options)   { { 'hostnames' => hostnames, 'quiet' => true } }

      run_on_server = true
      it_behaves_like 'shared all', run_on_server, false
      it_behaves_like 'shared all', run_on_server, true
    end

    context 'without valid hostname' do
      let(:hostnames) { build(:hostnames_not_allowed) }
      let(:args)      { { hostnames: hostnames, quiet: true } }
      let(:options)   { args.with_indifferent_access }
      # let(:options)   { { 'hostnames' => hostnames, 'quiet' => true } }

      run_on_server = false
      it_behaves_like 'shared all', run_on_server, false
      it_behaves_like 'shared all', run_on_server, true
    end

    context 'runs the job with SCHEDULER_ENTRY args' do
      let(:scheduler_entry) { described_class::SCHEDULER_ENTRY }
      let(:yaml)            { YAML.load scheduler_entry }
      let(:args)            { yaml[yaml.keys.first]['args'] }
      let(:hostnames)       { args['hostnames'] }
      let(:options)         { args.with_indifferent_access }

      run_on_server = false
      it_behaves_like 'shared all', run_on_server, false
      it_behaves_like 'shared all', run_on_server, true
    end

  end

end
