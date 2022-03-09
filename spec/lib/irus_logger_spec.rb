# frozen_string_literal: true

require 'rails_helper'

require_relative '../../lib/irus_logger'

RSpec.describe ::Deepblue::IrusLogger do
  let(:msg) { "The hobbits are going to Isengard." }
  let(:progname) { nil }
  let(:severity) {1}

  before do
    expect(::Deepblue::IRUS_LOGGER).to receive(:add).with(severity, progname, msg)
  end

  it 'formats messages' do
    ::Deepblue::IRUS_LOGGER.info msg
  end

end