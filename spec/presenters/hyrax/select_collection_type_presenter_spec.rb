require 'rails_helper'

RSpec.describe Hyrax::SelectCollectionTypePresenter, skip: false do
  subject { described_class.new(collection_type) }

  let(:collection_type) { create(:collection_type) }

  it { is_expected.to delegate_method(:title).to(:collection_type) }
  it { is_expected.to delegate_method(:description).to(:collection_type) }
  it { is_expected.to delegate_method(:admin_set?).to(:collection_type) }
  it { is_expected.to delegate_method(:id).to(:collection_type) }
end
