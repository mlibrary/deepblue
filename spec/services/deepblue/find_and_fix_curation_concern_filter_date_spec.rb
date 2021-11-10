# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Deepblue::FindAndFixCurationConcernFilterDate, skip: false do

  describe 'filters' do
    let(:begin_date)    { 'now - 7 days' }
    let(:end_date)      { 'now' }
    let(:test_date_in)  { DateTime.now - 1.day }
    let(:test_date_out) { DateTime.now - 10.day }
    let(:filter)        { described_class.new( begin_date: begin_date, end_date: end_date) }

    context 'in' do
      let(:work)        { build(:work, date_modified: test_date_in ) }

      it 'filters in' do
        expect( filter.include?( work.date_modified ) ).to eq true
      end
    end

    context 'out' do
      let(:work)        { build(:work, date_modified: test_date_out ) }

      it 'filters in' do
        expect( filter.include?( work.date_modified ) ).to eq false
      end
    end

  end

end
