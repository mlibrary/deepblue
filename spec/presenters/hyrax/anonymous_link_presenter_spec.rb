require 'rails_helper'

RSpec.describe Hyrax::AnonymousLinkPresenter, skip: false do

  subject { described_class.new(link) }

  context "with any kind of link" do
    let(:link) { create(:download_link) }

    describe "#short_key" do
      its(:short_key) { is_expected.to eq(link.downloadKey.first(6)) }
    end

    describe "delegated methods" do
      its(:downloadKey) { is_expected.to eq(link.downloadKey) }
      its(:expired?)    { is_expected.to eq(link.expired?) }
      its(:to_param)    { is_expected.to eq(link.to_param) }
    end
  end

  context "with a download link" do
    let(:link)        { create(:download_link) }

    its(:link_type)   { is_expected.to eq("Download") }
    its(:url_helper)  { is_expected.to eq("download_anonymous_link_url") }
  end

  context "with a show link" do
    let(:link)        { create(:show_link) }

    # its(:link_type)   { is_expected.to eq("Show") }
    its(:link_type)   { is_expected.to eq("View") }
    its(:url_helper)  { is_expected.to eq("show_anonymous_link_url") }
  end

end
