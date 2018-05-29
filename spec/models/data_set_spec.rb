# Generated via
#  `rails generate hyrax:work DataSet`
require 'rails_helper'

RSpec.describe DataSet do

  describe 'properties' do
    # it 'has private visibility when created' do
    #   expect(subject.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    # end

    it 'has subject property' do
      expect(subject).to respond_to(:subject)
    end

    it 'has identifier properties' do
      expect(subject).to respond_to(:doi)
      expect(subject).to respond_to(:hdl)
    end

    # describe 'resource type' do
    #   it 'is set during initialization' do
    #     expect(subject.resource_type).to eq ['Dataset']
    #   end
    # end
  end

  describe 'it requires core metadata' do
    before do
      subject.title = ['Demotitle']
      subject.creator = ['Demo Creator']
      # subject.date_created = ['2016-02-28']
      # subject.description = ['Demo description.']
      # subject.rights_license = ['Demo license.']
    end

    it 'validates title' do
      subject.title = []
      expect(subject).not_to be_valid
    end

    # it 'validates date_created' do
    #   subject.date_created = []
    #   expect(subject).not_to be_valid
    # end
    #
    # it 'validates description' do
    #   subject.description = []
    #   expect(subject).not_to be_valid
    # end
    #
    # it 'validates creator' do
    #   subject.creator = []
    #   expect(subject).not_to be_valid
    # end
    #
    # it 'validates rights_license' do
    #   subject.rights_license = []
    #   expect(subject).not_to be_valid
    # end
  end

end
