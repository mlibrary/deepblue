require 'rails_helper'

require_relative '../../app/services/deepblue/about_to_expire_embargoes_service'
require_relative '../../app/services/deepblue/message_handler'
require_relative '../../lib/tasks/about_to_expire_embargoes_task'

RSpec.describe ::Deepblue::AboutToExpireEmbargoesTask do

  describe 'run calls the service' do

    context 'empty options' do
      let(:options)  { {} }
      let(:expected) { { email_owner: true,
                         expiration_lead_days: nil,
                         skip_file_sets: true,
                         test_mode: false,
                         to_console: true,
                         verbose: false } }
      let(:task)     { described_class.new( options: options ) }
      let(:service)  { ::Deepblue::AboutToExpireEmbargoesService.allocate }

      it 'with expected args' do
        expect(::Deepblue::AboutToExpireEmbargoesService).to receive(:new) do |args|
          expect(args[:email_owner]).to eq expected[:email_owner]
          expect(args[:expiration_lead_days]).to eq expected[:expiration_lead_days]
          expect(args[:skip_file_sets]).to eq expected[:skip_file_sets]
          expect(args[:test_mode]).to eq expected[:test_mode]
          # expect(args[:to_console]).to eq expected[:to_console]
          # expect(args[:verbose]).to eq expected[:verbose]
          expect(args[:msg_handler].is_a? ::Deepblue::MessageHandler).to eq true
          expect(args[:msg_handler].to_console).to eq expected[:to_console]
          expect(args[:msg_handler].verbose).to eq expected[:verbose]
          expect(args[:msg_handler].debug_verbose).to eq false
        end.and_return service
        expect(service).to receive(:run)
        task.run
      end
    end

    context 'non-empty options' do
      let(:options)  { { email_owner: false,
                         expiration_lead_days: 8,
                         skip_file_sets: false,
                         test_mode: true,
                         to_console: false,
                         verbose: false } }
      let(:expected) { { email_owner: false,
                         expiration_lead_days: 8,
                         skip_file_sets: false,
                         test_mode: true,
                         verbose: false } }
      let(:task)     { described_class.new( options: options ) }
      let(:service)  { ::Deepblue::AboutToExpireEmbargoesService.allocate }

      it 'with expected args' do
        expect(::Deepblue::AboutToExpireEmbargoesService).to receive(:new) do |args|
          expect(args[:email_owner]).to eq expected[:email_owner]
          expect(args[:expiration_lead_days]).to eq expected[:expiration_lead_days]
          expect(args[:skip_file_sets]).to eq expected[:skip_file_sets]
          expect(args[:test_mode]).to eq expected[:test_mode]
          # expect(args[:to_console]).to eq true
          # expect(args[:verbose]).to eq expected[:verbose]
          expect(args[:msg_handler].is_a? ::Deepblue::MessageHandler).to eq true
          expect(args[:msg_handler].to_console).to eq false
          expect(args[:msg_handler].verbose).to eq expected[:verbose]
          expect(args[:msg_handler].debug_verbose).to eq false
        end.and_return service
        expect(service).to receive(:run)
        task.run
      end
    end

  end

end
