# frozen_string_literal: true

require_relative '../../../lib/scheduler_logger'

RSpec.describe Deepblue::SchedulerHelper, type: :helper, skip: false do

  describe 'module variables' do
    it { expect(described_class.scheduler_log_echo_to_rails_logger).to eq true }
  end

  describe '.log_raw' do
    let(:msg) { 'Schedule a pizza with calamari.' }
    before do
      expect(::Deepblue::SCHEDULER_LOGGER).to receive(:info).with msg
    end
    it 'receives the message' do
      described_class.log_raw msg
    end
  end

  describe '.log' do
    let(:class_name) { 'UnknownClass' }
    let(:event)      { 'unknown' }
    let(:event_note) { '' }
    let(:id)         { '' }
    let(:timestamp)  { DateTime.now }

    let(:hostname_allowed)   { 'Maybe' }
    let(:extra_value1)   { 'extra_value1' }

    let(:key_values)   do
      hash = { event: event,
               timestamp: timestamp,
               time_zone: ::Deepblue::LoggingHelper.timestamp_zone,
               class_name: class_name,
               id: id,
               extra_value1: extra_value1,
               hostname_allowed: hostname_allowed
      }
      ::Deepblue::JsonLoggerHelper.logger_json_encode(value: hash)
    end

    let(:expected_msg) { "#{timestamp} #{event}/#{event_note}/#{class_name}/#{id} #{key_values}" }

    before do
      expect(described_class).to receive(:log_raw).with expected_msg
      expect(Rails.logger).to receive(:info).with expected_msg
    end

    it 'gets the msg' do
      # puts;puts expected_msg
      expect(described_class.scheduler_log_echo_to_rails_logger).to eq true
      described_class.log( class_name: class_name,
                           event: event,
                           event_note: event_note,
                           id: id,
                           hostname_allowed: hostname_allowed,
                           timestamp: timestamp,
                           extra_value1: extra_value1 )
    end

  end

end
