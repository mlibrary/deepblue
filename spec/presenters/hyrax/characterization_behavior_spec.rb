require 'rails_helper'


class TestPresenter 
   include Hyrax::CharacterizationBehavior

   def human_readable(name)
     name
   end

end

RSpec.describe Hyrax::CharacterizationBehavior do

  let(:dummy_class) { double }

  it "checks if characterized" do
  	presenter = TestPresenter.new
  	allow(presenter).to receive(:characterization_metadata).and_return dummy_class
  	allow(dummy_class).to receive(:values).and_return []

    dc = presenter.characterized?

    expect(dc).to eq(false)
  end

  it "retrieves characterization metadata" do
  	presenter = TestPresenter.new
  	allow(presenter).to receive(:build_characterization_metadata).and_return "test"

    dc = presenter.characterization_metadata

    expect(dc).to eq("test")
  end

  it "retrieves characterization admin metadata" do
  	presenter = TestPresenter.new
  	allow(presenter).to receive(:build_characterization_metadata_admin_only).and_return "test"

    dc = presenter.characterization_metadata_admin_only

    expect(dc).to eq("test")
  end

  it "retrieves additional characterization metadata" do
  	presenter = TestPresenter.new

    dc = presenter.additional_characterization_metadata
    expect(dc).to eq({})
  end

  it "retrieves additional admin characterization metadata" do
  	presenter = TestPresenter.new

    dc = presenter.additional_characterization_metadata_admin_only
    expect(dc).to eq({})
  end

  it "retrieves label" do
  	presenter = TestPresenter.new

    dc = presenter.label_for_term "admin"
    expect(dc).to eq("Admin")
  end

  it "retrieves primary characterization value" do
  	presenter = TestPresenter.new
  	allow(presenter).to receive(:values_for).and_return ["Admin"]

    dc = presenter.primary_characterization_values "Admin"
    expect(dc).to eq(["Admin"])
  end

  it "retrieves admin primary characterization value" do
  	presenter = TestPresenter.new
  	allow(presenter).to receive(:values_for_admin_only).and_return ["Admin"]

    dc = presenter.primary_characterization_values_admin_only "Admin"
    expect(dc).to eq(["Admin"])
  end

  it "retrieves secondary characterization value" do
  	presenter = TestPresenter.new
  	allow(presenter).to receive(:values_for).and_return ["Admin"]

    dc = presenter.secondary_characterization_values "Admin"
    expect(dc).to eq([])
  end

  it "retrieves admin secondary characterization value" do
  	presenter = TestPresenter.new
  	allow(presenter).to receive(:values_for_admin_only).and_return ["Admin"]

    dc = presenter.secondary_characterization_values_admin_only "Admin"
    expect(dc).to eq([])
  end

end
