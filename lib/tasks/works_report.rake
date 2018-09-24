# frozen_string_literal: true

namespace :deepblue do

  # bundle exec rake deepblue:works_report
  desc 'Write report of all works'
  task :works_report, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    options = args[:options]
    task = Deepblue::WorksReport.new( options: options )
    task.run
  end

end

module Deepblue

  require 'tasks/curation_concern_report_task'
  require 'stringio'

  class WorksReport < CurationConcernReportTask

    # Produce a report containing:
    # * # of datasets
    # * Total size of the datasets in GB
    # * # of unique depositors
    # * # of repeat depositors
    # * Top 10 file formats (csv, nc, txt, pdf, etc)
    # * Discipline of dataset
    # * Names of depositors
    #

    def initialize( options: {} )
      super( options: options )
    end

    def run
      initialize_report_values
      report
    end

    protected

      def report
        out_report << "Report started: " << Time.new.to_s << "\n"
        @prefix = "#{Time.now.strftime('%Y%m%d')}_works_report"
        @works_file = Pathname.new( '.' ).join "#{prefix}_works.csv"
        @file_sets_file = Pathname.new( '.' ).join "#{prefix}_file_sets.csv"
        @out_works = open( works_file, 'w' )
        @out_file_sets = open( file_sets_file, 'w' )
        print_work_line( out_works, header: true )
        print_file_set_line( out_file_sets, header: true )

        process_works

        print "\n"
        print "#{works_file}\n"
        print "#{file_sets_file}\n"

        # puts
        # puts JSON.pretty_generate( @totals )
        # puts
        # puts JSON.pretty_generate( @tagged_totals )
        # puts

        report_finished
      ensure
        unless out_works.nil?
          out_works.flush
          out_works.close
        end
        unless out_file_sets.nil?
          out_file_sets.flush
          out_file_sets.close
        end
      end

  end

end
