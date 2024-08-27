# frozen_string_literal: true
# Reviewed: hyrax4

RSpec.describe Hyrax::SolrDocument::OrderedMembers do
  subject(:decorated) { described_class.decorate(document) }
  let(:data) { { id: parent_id } }
  let(:document) { SolrDocument.new(data) }
  let(:parent_id) { '1' }

  describe '#ordered_member_ids' do
    context 'with no id' do
      let(:data) { {} }

      it 'is empty' do
        expect(decorated.ordered_member_ids).to be_empty
      end
    end

    context 'with no members' do
      it 'is empty' do
        expect(decorated.ordered_member_ids).to be_empty
      end
    end

    # get an Ldp::Gone error
    # context 'with ordered members' do
    #   let(:parent) { create(:work_with_ordered_files) }
    #   let(:parent_id) { parent.id.to_s }
    #
    #   it 'has the file ids in exact order' do
    #     expect(decorated.ordered_member_ids).to eq parent.ordered_member_ids
    #   end
    # end
  end
end
