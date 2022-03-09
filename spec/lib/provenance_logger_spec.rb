# frozen_string_literal: true

require 'rails_helper'

require_relative '../../lib/provenance_logger'

RSpec.describe ::ProvenanceLogger do
  let(:msg) { "You simply don't walk into Moria." }
  let(:progname) { nil }
  let(:severity) {1}

  before do
    expect(::PROV_LOGGER).to receive(:add).with(severity, progname, msg)
  end

  it 'formats messages' do
    ::PROV_LOGGER.info msg
  end

end