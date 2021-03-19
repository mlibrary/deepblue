require 'rails_helper'

RSpec.describe WorkViewContentPresenter do
  subject { described_class.new(controller: controller, file_set: double, format: "", path: "/test", options: options) }
  let (:options) { {:menu => "test"} }
  let (:controller) { double("controllerA") }  

  before do
    allow(controller).to receive(:static_content_send).and_return "return value"
    allow(controller).to receive(:documentation_work_title_prefix).and_return "prefix-"
    allow(controller).to receive(:work_title).and_return "prefix-abc"
    allow(controller).to receive(:file_name).and_return "file_name"
  end

  it { expect( subject ).respond_to? :controller }
  it { expect( subject ).respond_to? :current? }
  it { expect( subject ).respond_to? :has_menu? }
  it { expect( subject ).respond_to? :menu }
  it { expect( subject ).respond_to? :menu_header }    
  it { expect( subject ).respond_to? :static_content }

  it 'expect menu to exists' do
     expect(subject.menu).to eq 'test'
     expect(subject.has_menu?).to eq true
  end

  it 'expect menu header to be missing' do
     expect(subject.menu_header).to eq 'Missing Header'
  end

  it 'expect static content to be available' do
     expect(subject.static_content).to eq 'return value'
  end

  context "check menu header options area available" do
    let (:options) { {:menu_header => "test.hyrax.text"} }

    it "contains appropriate value" do
      expect(subject.menu_header).to eq 'test.hyrax.text'
    end
  end

  context "check if work path is current" do
    it "determines path is current" do
      expect(subject.current? "/data/abc").to eq true
    end

    it "determines path is not current" do
      expect(subject.current? "/data/abcdef").to eq false
    end
  end
end
