# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Deepblue::AboutToExpireEmbargoesService do

  let(:debug_verbose) { false }

  describe 'constants' do
    it { expect( described_class.about_to_expire_embargoes_service_debug_verbose ).to eq debug_verbose }
  end

  let(:sched_helper) { class_double( Hyrax::EmbargoHelper ).as_stubbed_const(:transfer_nested_constants => true) }

  describe 'shared' do

    RSpec.shared_examples 'AboutToExpireEmbargoesService' do |dbg_verbose|
      let(:time_before)   { DateTime.now }
      let(:msg_handler)   { ::Deepblue::MessageHandler.new }
      before do
        described_class.about_to_expire_embargoes_service_debug_verbose = dbg_verbose
        expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(:once) if dbg_verbose
        expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug) unless dbg_verbose
      end
      after do
        described_class.about_to_expire_embargoes_service_debug_verbose = debug_verbose
      end

      it 'it calls the service' do
        time_after = DateTime.now
        service = described_class.new(email_owner: email_owner,
                                      expiration_lead_days: expiration_lead_days,
                                      msg_handler: msg_handler,
                                      skip_file_sets: skip_file_sets,
                                      test_mode: test_mode)
                                      # to_console: to_console,
                                      # verbose: verbose)
        expect(service).to receive(:assets_under_embargo).and_return []
        service.run
        # expect(job.timestamp_begin.between?(time_before,time_after)).to eq true
      end

    end

  end

  describe 'calls the service' do
    let(:email_owner)          { true }
    let(:expiration_lead_days) { 7 }
    let(:job_msg_queue)        { [] }
    let(:skip_file_sets)       { true }
    let(:test_mode)            { false }
    let(:to_console)           { false }
    let(:verbose)              { true }

    it_behaves_like 'AboutToExpireEmbargoesService', false
    it_behaves_like 'AboutToExpireEmbargoesService', true
  end

end
