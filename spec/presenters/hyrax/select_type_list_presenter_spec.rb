require 'rails_helper'

# Note: test app generates multiple work types (concerns) now
RSpec.describe Hyrax::SelectTypeListPresenter, skip: false do
  let(:instance) { described_class.new(user) }
  let(:user) { nil }

  describe "#many?" do
    subject { instance.many? }

    context 'without a logged in user' do
      it { is_expected.to be false }

      context "if user is nil" do
        it { is_expected.to be false }
      end
    end

    context 'with a logged in user' do
      let(:user) { factory_bot_create_user(:user) }

      it { is_expected.to be true }
      context "if authorized_models returns only one" do
        before do
          allow(instance).to receive(:authorized_models).and_return([double])
        end
        it { is_expected.to be false }
      end
    end
  end

  describe "#first_model" do
    let(:user) { factory_bot_create_user(:user) }

    subject { instance.first_model }

    it { is_expected.to be DataSet }
  end
end
