# frozen_string_literal: true

require 'rails_helper'

require_relative '../../lib/scheduler_logger'

RSpec.describe ::Deepblue::SchedulerLogger do
  let(:msg) { "Fly, you fools! Fly!" }
  let(:progname) { nil }
  let(:severity) {1}

  before do
    expect(::Deepblue::SCHEDULER_LOGGER).to receive(:add).with(severity, progname, msg)
  end

  it 'formats messages' do
    ::Deepblue::SCHEDULER_LOGGER.info msg
  end

end