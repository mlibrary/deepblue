# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Deepblue::AboutToExpireEmbargoesService do

  let(:sched_helper) { class_double( Hyrax::EmbargoHelper ).as_stubbed_const(:transfer_nested_constants => true) }

  describe 'constants' do
    it "resolves them" do
      expect( described_class.about_to_expire_embargoes_service_debug_verbose ).to eq false
    end
  end

  describe 'shared' do

    RSpec.shared_examples 'AboutToExpireEmbargoesService' do |debug_verbose_count|
      let(:dbg_verbose)   { debug_verbose_count > 0 }
      let(:time_before)   { DateTime.now }
      before do
        if 0 < debug_verbose_count
          expect(::Deepblue::LoggingHelper).to receive(:bold_debug).at_least(debug_verbose_count).times
        else
          expect(::Deepblue::LoggingHelper).to_not receive(:bold_debug)
        end
      end

      it 'it calls the service' do
        save_debug_verbose = described_class.about_to_expire_embargoes_service_debug_verbose
        described_class.about_to_expire_embargoes_service_debug_verbose = dbg_verbose
        time_after = DateTime.now
        service = described_class.new(email_owner: email_owner,
                                      expiration_lead_days: expiration_lead_days,
                                      job_msg_queue: job_msg_queue,
                                      skip_file_sets: skip_file_sets,
                                      test_mode: test_mode,
                                      to_console: to_console,
                                      verbose: verbose)
        expect(service).to receive(:assets_under_embargo).and_return []
        service.run
        # expect(job.timestamp_begin.between?(time_before,time_after)).to eq true
        described_class.about_to_expire_embargoes_service_debug_verbose = save_debug_verbose
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
    debug_verbose_count = 0
    it_behaves_like 'AboutToExpireEmbargoesService', debug_verbose_count
  end

end
