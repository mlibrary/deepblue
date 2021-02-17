# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdateCondensedEventsJob, skip: false do

  let(:analytics_helper) { class_double( AnalyticsHelper ).as_stubbed_const(:transfer_nested_constants => true) }
  let(:sched_helper) { class_double( Deepblue::SchedulerHelper ).as_stubbed_const(:transfer_nested_constants => true) }
  # let(:job_task_helper) { class_double( Deepblue::JobTaskHelper ).as_stubbed_const(:transfer_nested_constants => true) }

  context 'with valid arguments' do
    let(:hostname)  { 'some.host.name' }
    let(:job)       { described_class.send( :job_or_instantiate, *args ) }
    let(:hostnames) { build(:hostnames_allowed) }
    let(:args)      { { hostnames: hostnames, quiet: true } }
    let(:options)   { { 'hostnames' => hostnames, 'quiet' => true } }

    before do
      expect( described_class::UPDATE_CONDENSED_EVENTS_JOB_DEBUG_VERBOSE ).to eq false
      expect(sched_helper).to receive(:log).with( class_name: described_class.name,
                                                  event: "update condensed events job" )
      expect( analytics_helper ).to receive(:update_current_month_condensed_events)
      expect( job ).to receive( :job_options_value ).with( options,
                                                           key: 'quiet',
                                                           default_value: false,
                                                           verbose: false ).and_call_original
      expect( job ).to receive( :job_options_value ).with( options,
                                                           key: 'hostnames',
                                                           default_value: [],
                                                           verbose: false ).and_call_original
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

    before do
      expect( described_class::UPDATE_CONDENSED_EVENTS_JOB_DEBUG_VERBOSE ).to eq false
      expect(sched_helper).to receive(:log).with( class_name: described_class.name,
                                                  event: "update condensed events job" )
      expect( analytics_helper ).to_not receive(:update_current_month_condensed_events)
      expect( job ).to receive( :job_options_value ).with( options,
                                                           key: 'quiet',
                                                           default_value: false,
                                                           verbose: false ).and_call_original
      expect( job ).to receive( :job_options_value ).with( options,
                                                           key: 'hostnames',
                                                           default_value: [],
                                                           verbose: false ).and_call_original
    end

    it 'does not call update_current_month_condensed_events' do
      ActiveJob::Base.queue_adapter = :test
      job.perform_now # arguments set in the describe_class.send :job_or_instatiate above
    end
  end


end
