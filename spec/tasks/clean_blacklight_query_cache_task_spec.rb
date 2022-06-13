require 'rails_helper'

require_relative '../../app/helpers/deepblue/clean_up_helper'
require_relative '../../app/services/deepblue/message_handler'
require_relative '../../lib/tasks/clean_blacklight_query_cache_task'

RSpec.describe ::Deepblue::CleanBlacklightQueryCacheTask do

  describe 'run calls the service' do

    context 'empty options' do
      let(:options) { { } }
      let(:task) { described_class.new( options: options ) }

      it 'with expected args' do
        expect(::Deepblue::CleanUpHelper).to receive(:clean_blacklight_query_cache) do |args|
          expect(args[:increment_day_span]).to eq 15
          expect(args[:start_day_span]).to eq 30
          expect(args[:max_day_spans]).to eq 0
          expect(args[:msg_handler].is_a? ::Deepblue::MessageHandler).to eq true
          expect(args[:msg_handler].msg_queue).to eq nil
          expect(args[:msg_handler].to_console).to eq true
          expect(args[:msg_handler].verbose).to eq false
          expect(args[:task]).to eq true
          expect(args[:debug_verbose]).to eq false
        end
        task.run
      end
    end

    context 'non-empty options' do
      let(:options) { { start_day_span: 45, increment_day_span: 10, max_day_spans: 5, verbose: true } }
      let(:task) { described_class.new( options: options ) }

      it 'with expected args' do
        expect(::Deepblue::CleanUpHelper).to receive(:clean_blacklight_query_cache) do |args|
          expect(args[:increment_day_span]).to eq 10
          expect(args[:start_day_span]).to eq 45
          expect(args[:max_day_spans]).to eq 5
          expect(args[:msg_handler].is_a? ::Deepblue::MessageHandler).to eq true
          expect(args[:msg_handler].msg_queue).to eq nil
          expect(args[:msg_handler].to_console).to eq true
          expect(args[:msg_handler].verbose).to eq true
          expect(args[:task]).to eq true
          expect(args[:verbose]).to eq true
          expect(args[:debug_verbose]).to eq false
        end
        task.run
      end
    end

  end

end
