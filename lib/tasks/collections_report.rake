# frozen_string_literal: true

namespace :deepblue do

  # bundle exec rake deepblue:collections_report
  desc 'Write report of all collections'
  task :collections_report, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    options = args[:options]
    task = Deepblue::CollectionsReport.new( options: options )
    task.run
  end

end

module Deepblue

  require 'tasks/curation_concern_report_task'
  require 'stringio'

  class CollectionsReport < CurationConcernReportTask

    # Produce a report containing: TODO
    # * # of datasets
    # * Total size of the datasets in GB
    # * # of unique depositors
    # * # of repeat depositors
    # * Top 10 file formats (csv, nc, txt, pdf, etc)
    # * Discipline of dataset
    # * Names of depositors

    def initialize( options: {} )
      super( options: options )
    end

    def run
      initialize_report_values
      report
    end

    protected

      def initialize_report_values
        super()
      end

      def report
        out_report << "Report started: " << Time.new.to_s << "\n"
        @prefix = "#{Time.now.strftime('%Y%m%d')}_collections_report" if @prefix.nil?
        @collections_file = Pathname.new( report_dir ).join "#{prefix}_collections.csv"
        @works_file = Pathname.new( report_dir ).join "#{prefix}_works.csv"
        @file_sets_file = Pathname.new( report_dir ).join "#{prefix}_file_sets.csv"
        @out_collections = open( collections_file, 'w' )
        @out_works = open( works_file, 'w' )
        @out_file_sets = open( file_sets_file, 'w' )

        print_collection_line( out_collections, header: true )
        print_work_line( out_works, header: true )
        print_file_set_line( out_file_sets, header: true )

        process_collections

        print "\n"
        print "#{collections_file}\n"
        print "#{works_file}\n"
        print "#{file_sets_file}\n"

        report_finished
      ensure
        unless out_collections.nil?
          out_collections.flush
          out_collections.close
        end
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
