# frozen_string_literal: true
# hyrax-orcid

require 'rails_helper'

RSpec.describe Hyrax::Orcid::OrcidHelper do
  include Devise::Test::ControllerHelpers

  let(:helper) { _view }

  let(:domain) { "https://orcid.org/" }
  let(:sandbox_domain) { "https://sandbox.orcid.org/" }
  let(:orcid) { "0000-1234-1234-1234" }
  let(:orcid_with_spaces) { "0000 1234 1234 1234" }
  let(:orcid_with_no_delimiter) { "0000123412341234" }
  let(:x_orcid) { "0000-1234-1234-123X" }
  let(:invalid_orcid) { "this-is-not-an-orcid" }

  describe "validate_orcid" do
    it { expect(helper.validate_orcid(orcid)).to eq(orcid) }
    it { expect(helper.validate_orcid(sandbox_domain + orcid)).to eq(orcid) }
    it { expect(helper.validate_orcid(domain + orcid)).to eq(orcid) }

    it { expect(helper.validate_orcid(orcid_with_spaces)).to eq(orcid) }
    it { expect(helper.validate_orcid(sandbox_domain + orcid_with_spaces)).to eq(orcid) }
    it { expect(helper.validate_orcid(domain + orcid_with_spaces)).to eq(orcid) }

    it { expect(helper.validate_orcid(orcid_with_no_delimiter)).to eq(orcid) }
    it { expect(helper.validate_orcid(sandbox_domain + orcid_with_no_delimiter)).to eq(orcid) }
    it { expect(helper.validate_orcid(domain + orcid_with_no_delimiter)).to eq(orcid) }

    it { expect(helper.validate_orcid(x_orcid)).to eq(x_orcid) }
    it { expect(helper.validate_orcid(sandbox_domain + x_orcid)).to eq(x_orcid) }
    it { expect(helper.validate_orcid(domain + x_orcid)).to eq(x_orcid) }

    it { expect(helper.validate_orcid(invalid_orcid)).to be_nil }
    it { expect(helper.validate_orcid(sandbox_domain + invalid_orcid)).to be_nil }
    it { expect(helper.validate_orcid(domain + invalid_orcid)).to be_nil }
  end
end
