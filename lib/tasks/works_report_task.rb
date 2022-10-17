# frozen_string_literal: true

module Deepblue

  require 'tasks/curation_concern_report_task'
  require 'stringio'

  class WorksReportTask < CurationConcernReportTask

    # Produce a report containing:
    # * # of datasets
    # * Total size of the datasets in GB
    # * # of unique depositors
    # * # of repeat depositors
    # * Top 10 file formats (csv, nc, txt, pdf, etc)
    # * Discipline of dataset
    # * Names of depositors
    #

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
    end

    def run
      initialize_report_values
      report
    end

    protected

      def report
        out_report << "Report server: #{Rails.configuration.hostname}" << "\n"
        out_report << "Report started: " << Time.new.to_s << "\n"
        @prefix = "#{Time.now.strftime('%Y%m%d')}_works_report" if @prefix.nil?
        @works_file = Pathname.new( report_dir ).join "#{prefix}_works.csv"
        @file_sets_file = Pathname.new( report_dir ).join "#{prefix}_file_sets.csv"
        @out_works = File.open( works_file, 'w' )
        @out_file_sets = File.open( file_sets_file, 'w' )
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
