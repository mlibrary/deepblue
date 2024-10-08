# frozen_string_literal: true
# Update: hyrax4

require 'rails_helper'

RSpec.describe Hyrax::PermissionBadge, skip: false do

  context "with a SolrDocument" do
    let(:badge) { described_class.new(solr_doc.visibility) }
    let(:solr_doc) { SolrDocument.new(attributes) }
    let(:attributes) { {} }

    describe "#render" do
      subject { badge.render }

      context "when under embargo" do
        let(:attributes) { { read_access_group_ssim: ['public'], embargo_release_date_dtsi: '2016-05-04' } }

        it { is_expected.to eq "<span class=\"badge badge-warning\">Embargo</span>" }
      end

      context "when under lease" do
        let(:attributes) { { read_access_group_ssim: ['public'], lease_expiration_date_dtsi: '2016-05-04' } }

        it { is_expected.to eq "<span class=\"badge badge-warning\">Lease</span>" }
      end

      context "when open-access" do
        let(:attributes) { { read_access_group_ssim: ['public'] } }

        it { is_expected.to eq "<span class=\"badge badge-success\">Open Access</span>" }
      end

      context "when registered" do
        let(:attributes) { { read_access_group_ssim: ['registered'] } }

        it { is_expected.to eq "<span class=\"badge badge-info\">Institution</span>" }
      end

      context "when private" do
        it { is_expected.to eq "<span class=\"badge badge-danger\">Restricted</span>" }
      end

      # solr document can have no visibility indexed
      it "does not fail when nil is passed" do
        badge = described_class.new(nil)

        expect(badge.render).to eq "<span class=\"badge badge-info\">Unknown</span>"
      end
    end
  end

  context "with a string" do
    let(:badge) { described_class.new(value) }

    describe "#render" do
      subject { badge.render }

      context "when under embargo" do
        let(:value) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO }

        it { is_expected.to eq "<span class=\"badge badge-warning\">Embargo</span>" }
      end

      context "when under lease" do
        let(:value) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE }

        it { is_expected.to eq "<span class=\"badge badge-warning\">Lease</span>" }
      end

      context "when open-access" do
        let(:value) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }

        it { is_expected.to eq "<span class=\"badge badge-success\">Open Access</span>" }
      end

      context "when registered" do
        let(:value) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }

        it { is_expected.to eq "<span class=\"badge badge-info\">Institution</span>" }
      end

      context "when private" do
        let(:value) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }

        it { is_expected.to eq "<span class=\"badge badge-danger\">Restricted</span>" }
      end
    end
  end
end
