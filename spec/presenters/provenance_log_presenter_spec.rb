require 'rails_helper'

class TestProvPresenter < ProvenanceLogPresenter
end

RSpec.describe ProvenanceLogPresenter do

  let(:dummy_class) { double }
  let(:dummy2_class) { double }

  it "generates a download path link" do
    presenter = TestProvPresenter.new controller: dummy_class
    dc = presenter.display_title "Title of of work"

    expect(dc).to eq("Title of of work")
  end

  it "returns if there is a provenance log entry" do
    presenter = TestProvPresenter.new controller: dummy_class
    allow(dummy_class).to receive(:id).and_return "the id"
    dc = presenter.provenance_log_entries?

    expect(dc).to eq(false)
  end

  it "returns if provenance is enabled" do
    presenter = TestProvPresenter.new controller: dummy_class
    dc = presenter.provenance_log_display_enabled?

    expect(dc).to eq(true)
  end

  it "returns path for action" do
    presenter = TestProvPresenter.new controller: dummy_class
    dc = presenter.url_for action:'show', id: nil, only_path: true 

    expect(dc).to eq("/provenance_log")
  end

  it "returns path for show an id" do
    presenter = TestProvPresenter.new controller: dummy_class
    dc = presenter.url_for_id id:2 , only_path: true

    expect(dc).to eq("/provenance_log/2")
  end
end
