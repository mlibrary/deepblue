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

    let(:report_task) { double(::Deepblue::ReportTask) }

    describe "for date with format" do
      let( :attribute ) { 'some_attribute' }
      let( :date1 )     { '2021-04-01' }
      let( :date2 )     { '2021-05-01' }
      let( :format )    { "%Y-%m-%d" }
      let( :parms )     { { begin: date1, end: date2, format: format } }
      let( :filter )    { ::Deepblue::CurationConcernFilterDate.new( report_task: report_task,
                                                                     attribute: attribute,
                                                                     parms: parms ) }
      it 'creates the date using the specified format' do
        expect( filter.begin_date ).to eq DateTime.strptime( date1, format )
        expect( filter.end_date ).to eq DateTime.strptime( date2, format )
      end

      it "does not parse with bad format" do
        expect( report_task ).to receive(:msg_puts).with("Failed to format the date string '2021-04-01' using format 'YYYY-MM-DD-is_bad' for entry 'begin_date'")
        expect { ::Deepblue::CurationConcernFilterDate.new( report_task: report_task,
                                                            attribute: attribute,
                                                            parms: { begin: date1,
                                                                     end: date2,
                                                                     format: "YYYY-MM-DD-is_bad" } )
        }.to raise_error ArgumentError, "invalid date"
      end

    end

    describe 'for date == now' do
      let( :now1 ) { DateTime.now }
      let( :attribute ) { 'some_attribute' }
      let( :parms ) { { begin: 'now', end: 'now' } }
      let( :filter ) { ::Deepblue::CurationConcernFilterDate.new( report_task: report_task,
                                                                  attribute: attribute,
                                                                  parms: parms ) }

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
      let( :filter ) { ::Deepblue::CurationConcernFilterDate.new( report_task: report_task,
                                                                  attribute: attribute,
                                                                  parms: parms ) }

      it 'is 1 day before and 1 day after now' do
        now2_minus_day = DateTime.now - 1.day
        now2_plus_day = DateTime.now + 1.day
        expect( filter.begin_date ).to be_between( now1_minus_day, now2_minus_day )
        expect( filter.end_date ).to be_between( now1_plus_day, now2_plus_day )
      end

      it "parses now - 14 days" do
        ::Deepblue::CurationConcernFilterDate.new( report_task: report_task,
                                                   attribute: attribute,
                                                   parms: { begin: 'now - 14 days', end: 'now + 14 days' } )
      end

      it "parses now - 2 weeks" do
        ::Deepblue::CurationConcernFilterDate.new( report_task: report_task,
                                                   attribute: attribute,
                                                   parms: { begin: 'now - 2 weeks', end: 'now + 2 weeks' } )
      end

      it "does not parse now - 1 foobar" do
        expect( report_task ).to receive(:msg_puts).with("Failed parse relative ('now') date string 'now - 1 foobar' (ignoring format '') for entry 'begin_date'")
        expect { ::Deepblue::CurationConcernFilterDate.new( report_task: report_task,
                                                   attribute: attribute,
                                                   parms: { begin: 'now - 1 foobar', end: 'now + 1 foobar' } )
               }.to raise_error ArgumentError, "invalid date"
      end

    end

  end

end
