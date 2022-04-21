require 'rails_helper'

RSpec.describe Hyrax::PresenterRenderer, type: :view, skip: false do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect( described_class.presenter_renderer_debug_verbose ).to eq debug_verbose }
  end
  let(:user) { create(:admin) }

  let(:ability) { double }
  let(:document) { SolrDocument.new(data) }
  let(:data) do
    { id: '123', date_created_tesim: 'foo', date_uploaded_tesim: 'bar', has_model_ssim: 'DataSet' }
  end
  let(:presenter) { Hyrax::WorkShowPresenter.new(document, ability) }
  let(:renderer) { described_class.new(presenter, view) }

  describe "#label" do
    it "calls translate with defaults" do
      expect(renderer).to receive(:t).with(:"data_set.date_created",
                                           default: [:"defaults.date_created", "Date created"],
                                           scope: :"simple_form.labels")
      renderer.label(:date_created)
    end

    context "of a field with a translation" do
      subject { renderer.label(:date_created) }

      it { is_expected.to eq 'Date Created' }
    end

    context "of a field without a translation" do
      subject { renderer.label(:date_uploaded) }

      it { is_expected.to eq 'Date uploaded' }
    end
  end

end
