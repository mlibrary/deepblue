# frozen_string_literal: true

require 'rails_helper'

require_relative '../../../lib/hyrax/contact_form_logger'

RSpec.describe ::Hyrax::CONTACT_FORM_LOGGER do
  let(:msg) { "Fly, you fools! Fly!" }
  let(:progname) { nil }
  let(:severity) {1}

  before do
    expect(::Hyrax::CONTACT_FORM_LOGGER).to receive(:add).with(severity, progname, msg)
  end

  it 'formats messages' do
    ::Hyrax::CONTACT_FORM_LOGGER.info msg
  end

end