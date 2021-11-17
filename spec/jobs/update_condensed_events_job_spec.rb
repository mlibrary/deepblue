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

  describe 'all', skip: false do
    RSpec.shared_examples 'shared all' do |dbg_verbose|
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
          let(:hostname)  { 'some.host.name' }
          let(:job)       { described_class.send( :job_or_instantiate, *args ) }
          let(:hostnames) { build(:hostnames_allowed) }
          let(:args)      { { hostnames: hostnames, quiet: true } }
          let(:options)   { { 'hostnames' => hostnames, 'quiet' => true } }
          let(:task)      { false }

          before do
            # TODO: reactivate this
            # expect(sched_helper).to receive(:log).with( class_name: described_class.name,
            #                                             event: "update condensed events job" )
            allow(sched_helper).to receive(:log)
            allow(sched_helper).to receive(:scheduler_log_echo_to_rails_logger).and_return false
            expect( analytics_helper ).to receive(:update_current_month_condensed_events)
            expect(job).to receive(:job_options_value).with( options,
                                                             key: 'hostnames',
                                                             default_value: [],
                                                             verbose: dbg_verbose,
                                                             task: task ).and_call_original
            expect(job).to receive(:job_options_value).with( options,
                                                             key: 'task',
                                                             default_value: false,
                                                             task: task ).and_call_original
            expect(job).to receive(:job_options_value).with( options,
                                                             key: 'verbose',
                                                             default_value: false,
                                                             task: task ).and_call_original
            expect(job).to receive(:job_options_value).with( options,
                                                             key: 'user_email',
                                                             default_value: '',
                                                             task: task ).and_call_original
            expect(job).to receive(:job_options_value).with( options,
                                                             key: 'quiet',
                                                             default_value: false,
                                                             verbose: dbg_verbose,
                                                             task: task ).and_call_original
          end

          it 'calls update_current_month_condensed_events' do
            ActiveJob::Base.queue_adapter = :test
            job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
          end
        end

        context 'without valid hostnames' do
          let(:job)       { described_class.send( :job_or_instantiate, *args ) }
          let(:hostnames) { [  ] }
          let(:args)      { { hostnames: hostnames, quiet: true } }
          let(:options)   { { 'hostnames' => hostnames, 'quiet' => true } }
          let(:task)      { false }

          before do
            # TODO: reactivate this
            # expect(sched_helper).to receive(:log).with( class_name: described_class.name,
            #                                             event: "update condensed events job" )
            allow(sched_helper).to receive(:log)
            allow(sched_helper).to receive(:scheduler_log_echo_to_rails_logger).and_return false
            expect( analytics_helper ).to_not receive(:update_current_month_condensed_events)
            expect(job).to receive(:job_options_value).with( options,
                                                             key: 'hostnames',
                                                             default_value: [],
                                                             verbose: dbg_verbose,
                                                             task: task ).at_least(:once).and_call_original
            expect(job).to receive(:job_options_value).with( options,
                                                             key: 'task',
                                                             default_value: false,
                                                             task: task ).and_call_original
            expect(job).to receive(:job_options_value).with( options,
                                                             key: 'verbose',
                                                             default_value: false,
                                                             task: task ).and_call_original
            expect(job).to receive(:job_options_value).with( options,
                                                             key: 'user_email',
                                                             default_value: '',
                                                             task: task ).and_call_original
            expect(job).to receive(:job_options_value).with( options,
                                                             key: 'quiet',
                                                             default_value: false,
                                                             verbose: dbg_verbose ,
                                                             task: task).and_call_original
            # expect(job).to receive(:job_options_value).with( options,
            #                                                      key: 'hostnames',
            #                                                      default_value: [],
            #                                                      verbose: dbg_verbose ,
            #                                                              task: task ).and_call_original
          end

          it 'does not call update_current_month_condensed_events' do
            ActiveJob::Base.queue_adapter = :test
            job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
          end
        end

      end
    end
    it_behaves_like 'shared all', false
    it_behaves_like 'shared all', true
  end

end
