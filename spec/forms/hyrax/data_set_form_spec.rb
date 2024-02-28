# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::DataSetForm do

  let(:debug_verbose) { false }

  describe 'module debug verbose variables' do
    it { expect(described_class.data_set_form_debug_verbose).to eq debug_verbose }
  end

  subject { form }
  let(:work) { DataSet.new }
  let(:user) { create(:user) }
  let(:ability) { Ability.new(user) }
  let(:form) { described_class.new(work, ability, nil) }

  let( :expected_required_fields ) do
    %i[
    title
    creator
    authoremail
    methodology
    description
    rights_license
    subject_discipline
    ]
  end
  let( :expected_primary_terms ) do
    rv = %i[
    title
    depositor_creator
    creator
    creator_orcid
    authoremail
    methodology
    tombstone
    description
    date_coverage
    rights_license
    rights_license_other
    subject_discipline
    fundedby
    fundedby_other
    grantnumber
    keyword
    language
    referenced_by
    access_deepblue
    ]
    rv
  end

  describe "#required_fields" do
    subject { form.required_fields }

    it { is_expected.to eq expected_required_fields }
  end

  describe "#primary_terms" do
    subject { form.primary_terms }
    it do
      is_expected.to eq expected_primary_terms
    end
  end

  describe "#secondary_terms" do
    subject { form.secondary_terms }

    it do
      is_expected.not_to include( :title,
                                  :creator,
                                  :keyword,
                                  :visibilty,
                                  :visibility_during_embargo,
                                  :embargo_release_date,
                                  :visibility_after_embargo,
                                  :visibility_during_lease,
                                  :lease_expiration_date,
                                  :visibility_arights_statementfter_lease,
                                  :collection_ids,
                                  :additional_information )
      is_expected.not_to include( *expected_required_fields )
      is_expected.not_to include( *expected_primary_terms )
      # is_expected.to include( :additional_information )
    end
  end

  describe "#[]" do
    subject { form[term] }

    context "for member_of_collection_ids" do
      let(:term) { :member_of_collection_ids }

      it { is_expected.to eq [] }

      context "when the model has collection ids" do
        before do
          allow(work).to receive(:member_of_collection_ids).and_return(['col1', 'col2'])
        end
        # This allows the edit form to show collections the work is already a member of.
        it { is_expected.to eq ['col1', 'col2'] }
      end
    end
  end

  describe '.model_attributes' do # rubocop:disable RSpec/EmptyExampleGroup
    let(:permission_template) { create(:permission_template, source_id: source_id) }
    let!(:workflow) { create(:workflow, active: true, permission_template_id: permission_template.id) }
    let(:source_id) { '123' }
    let(:file_set) { create(:file_set) }
    let(:params) do
      ActionController::Parameters.new(
          title: ['foo'],
          description: [''],
          visibility: 'open',
          source_id: source_id,
          representative_id: '456',
          rendering_ids: [file_set.id],
          thumbnail_id: '789',
          keyword: ['derp'],
          license: ['http://creativecommons.org/licenses/by/3.0/us/'],
          member_of_collection_ids: ['123456', 'abcdef']
      )
    end

    subject { described_class.model_attributes(params) }

    it 'permits parameters' do
      expect(subject['title']).to eq ['foo']
      expect(subject['description']).to be_empty
      expect(subject['visibility']).to eq 'open'
      expect(subject['license']).to eq ['http://creativecommons.org/licenses/by/3.0/us/']
      expect(subject['keyword']).to eq ['derp']
      expect(subject['member_of_collection_ids']).to eq ['123456', 'abcdef']
      expect(subject['rendering_ids']).to eq [file_set.id]
    end

    context '.model_attributes' do
      let(:params) do
        ActionController::Parameters.new(
            title: [''],
            description: [''],
            keyword: [''],
            license: [''],
            member_of_collection_ids: [''],
            on_behalf_of: 'Melissa'
        )
      end

      it 'removes blank parameters' do
        expect(subject['title']).to be_empty
        expect(subject['description']).to be_empty
        expect(subject['license']).to be_empty
        expect(subject['keyword']).to be_empty
        expect(subject['member_of_collection_ids']).to be_empty
        expect(subject['on_behalf_of']).to eq 'Melissa'
      end
    end
  end

  describe "#visibility" do
    subject { form.visibility }

    it { is_expected.to eq 'open' }
  end

  it { is_expected.to delegate_method(:on_behalf_of).to(:model) }
  it { is_expected.to delegate_method(:depositor).to(:model) }
  it { is_expected.to delegate_method(:permissions).to(:model) }

  describe "#agreement_accepted" do
    subject { form.agreement_accepted }

    it { is_expected.to eq false }
  end

  context "on a work already saved" do
    before { allow(work).to receive(:new_record?).and_return(false) }
    it "defaults deposit agreement to true" do
      expect(form.agreement_accepted).to eq(true)
    end
  end

end
