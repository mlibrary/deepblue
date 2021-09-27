require 'rails_helper'

class TestPresenter 
   include Hyrax::CreateWorkPresenterBehavior
end


RSpec.describe Hyrax::CreateWorkPresenterBehavior do

  let(:dummy_class) { double }

  xit "retrieves characterization metadata" do
  	presenter = TestPresenter.new
  	allow(Hyrax::CreateWorkPresenterBehavior).to receive(:create_work_presenter_class).and_return "test"

    dc = presenter.create_work_presenter

    expect(dc).to eq("test")
  end

  it "checks if create many types" do
  	presenter = TestPresenter.new
  	allow(Flipflop).to receive(:only_use_data_set_work_type?).and_return true

    dc = presenter.create_many_work_types?

    expect(dc).to eq(false)
  end

  it "checks it should draw work modal" do
  	presenter = TestPresenter.new

    dc = presenter.draw_select_work_modal?

    expect(dc).to eq(false)
  end

  it "checks it should draw work modal" do
  	presenter = TestPresenter.new
  	allow(presenter).to receive(:create_work_presenter).and_return dummy_class
  	allow(dummy_class).to receive(:first_model).and_return "model"

    dc = presenter.first_work_type

    expect(dc).to eq("model")
  end

end
