# frozen_string_literal: true

require 'rails_helper'

require_relative '../../lib/upload_logger'

RSpec.describe ::Deepblue::UploadLogger do
  let(:msg) { "Fly, you fools! Fly!" }
  let(:progname) { nil }
  let(:severity) {1}

  before do
    expect(::Deepblue::UPLOAD_LOGGER).to receive(:add).with(severity, progname, msg)
  end

  it 'formats messages' do
    ::Deepblue::UPLOAD_LOGGER.info msg
  end

end