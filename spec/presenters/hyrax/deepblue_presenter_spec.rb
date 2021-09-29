# frozen_string_literal: true

require 'rails_helper'

class TestDeepbluePresenter < Hyrax::DeepbluePresenter
end

RSpec.describe Hyrax::DeepbluePresenter do

  let(:dummy_class) { double }
  let(:dummy2_class) { double }

  it "checks if box is enabled" do
    presenter = TestDeepbluePresenter.new dummy_class, dummy2_class
    dc = presenter.box_enabled? 

    expect(dc).to eq(false)
  end

  it "checks if provenance log is enabled" do
    presenter = TestDeepbluePresenter.new dummy_class, dummy2_class
    dc = presenter.display_provenance_log_enabled?

    expect(dc).to eq(false)
  end

  it "checks if doi minting is enabled" do
    presenter = TestDeepbluePresenter.new dummy_class, dummy2_class
    dc = presenter.doi_minting_enabled?

    expect(dc).to eq(false)
  end

  it "checks if globus download is enabled" do
    presenter = TestDeepbluePresenter.new dummy_class, dummy2_class
    dc = presenter.globus_download_enabled?

    expect(dc).to eq(false)
  end

  it "get human readable types" do
    presenter = TestDeepbluePresenter.new dummy_class, dummy2_class
    dc = presenter.human_readable_type

    expect(dc).to eq("Work")
  end

  xit "get human readable types" do
    presenter = TestDeepbluePresenter.new dummy_class, dummy2_class
    allow(MemberPresenterFactory).to receive(:new).and_return true
    dc = presenter.member_presenter_factory

    expect(dc).to eq(true)
  end

  it "get permission status for tombston hack" do
    presenter = TestDeepbluePresenter.new dummy_class, dummy2_class
    dc = presenter.tombstone_permissions_hack?

    expect(dc).to eq(false)
  end

end
