# frozen_string_literal: true

require 'rails_helper'

require_relative "../../lib/tasks/report_task"

RSpec.describe ::Deepblue::ReportTask, skip: false do

  describe 'constants', skip: false do
    it "resolves them" do
      expect( described_class.report_task_debug_verbose ).to eq false
    end
  end

  context 'attr_readers' do
    # let( :report_definitions_file ) { './report.yml' }

    it "responds to" do
      subject { described_class.new }
      expect( subject.respond_to? :current_child ).to eq true
      expect( subject.respond_to? :current_child_index ).to eq true
      expect( subject.respond_to? :curation_concern ).to eq true
      expect( subject.respond_to? :config ).to eq true
      expect( subject.respond_to? :fields ).to eq true
      expect( subject.respond_to? :field_formats ).to eq true
      expect( subject.respond_to? :filters ).to eq true
      expect( subject.respond_to? :output ).to eq true
      expect( subject.respond_to? :filter_exclude ).to eq true
      expect( subject.respond_to? :filter_include ).to eq true
      expect( subject.respond_to? :include_children ).to eq true
      expect( subject.respond_to? :include_children_parent_columns_blank ).to eq true
      expect( subject.respond_to? :include_children_parent_columns ).to eq true
      expect( subject.respond_to? :report_definitions ).to eq true
      expect( subject.respond_to? :report_definitions_file ).to eq true
      expect( subject.respond_to? :field_format_strings ).to eq true
      expect( subject.respond_to? :output_file ).to eq true
      expect( subject.respond_to? :reporter ).to eq true
      expect( subject.respond_to? :allowed_path_prefixes ).to eq true
    end

  end

  context 'CurationConcernFilterDate' do

    describe 'for date == now' do
      let( :now1 ) { DateTime.now }
      let( :attribute ) { 'some_attribute' }
      let( :parms ) { { begin: 'now', end: 'now' } }
      let( :filter ) { ::Deepblue::CurationConcernFilterDate.new( attribute: attribute, parms: parms ) }

      it 'is now' do
        now2 = DateTime.now
        expect( filter.begin_date ).to be_between( now1, now2 )
        expect( filter.end_date ).to be_between( now1, now2 )
      end

    end

    describe 'for date == now' do
      let( :now1_minus_day ) { DateTime.now - 1.day }
      let( :now1_plus_day ) { DateTime.now + 1.day }
      let( :attribute ) { 'some_attribute' }
      let( :parms ) { { begin: 'now - 1 day', end: 'now + 1 day' } }
      let( :filter ) { ::Deepblue::CurationConcernFilterDate.new( attribute: attribute, parms: parms ) }

      it 'is 1 day before and 1 day after now' do
        now2_minus_day = DateTime.now - 1.day
        now2_plus_day = DateTime.now + 1.day
        expect( filter.begin_date ).to be_between( now1_minus_day, now2_minus_day )
        expect( filter.end_date ).to be_between( now1_plus_day, now2_plus_day )
      end

    end

  end

end
