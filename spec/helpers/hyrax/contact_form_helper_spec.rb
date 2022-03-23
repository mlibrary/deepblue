# frozen_string_literal: true

require_relative '../../../lib/hyrax/contact_form_logger'

RSpec.describe Hyrax::ContactFormHelper, type: :helper, skip: false do


  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.contact_form_helper_debug_verbose ).to eq debug_verbose }
  end

  describe 'module variables' do
    it { expect(described_class.contact_form_log_echo_to_rails_logger).to eq true }
  end

  describe '.log_raw' do
    let(:msg) { 'Requesting a pizza with anchovies.' }
    before do
      expect(Hyrax::CONTACT_FORM_LOGGER).to receive(:info).with msg
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

    let(:category)   { 'Depositing content' }
    let(:name)       { 'Rose Tyler' }
    let(:email)      { 'rose@timetraveler.org' }
    let(:subject)    { 'The Doctor' }
    let(:message)    { 'Run' }
    let(:contact_method) { nil } # filled in for spam
    let(:extra_value1)   { 'extra_value1' }

    let(:key_values)   do
      hash = { event: event,
               timestamp: timestamp,
               time_zone: ::Deepblue::LoggingHelper.timestamp_zone,
               class_name: class_name,
               id: id,
               extra_value1: extra_value1,
               contact_method: contact_method,
               category: category,
               name: name,
               email: email,
               subject: subject,
               message: message
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
      expect(described_class.contact_form_log_echo_to_rails_logger).to eq true
      described_class.log( class_name: class_name,
                           event: event,
                           event_note: event_note,
                           id: id,
                           timestamp: timestamp,
                           echo_to_rails_logger: true,
                           contact_method: contact_method,
                           category: category,
                           name: name,
                           email: email,
                           subject: subject,
                           message: message,
                           extra_value1: extra_value1 )
    end

  end

end
