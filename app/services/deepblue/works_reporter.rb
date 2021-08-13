# frozen_string_literal: true

module Deepblue

  require 'stringio'
  require_relative './curation_concern_reporter'

  class WorksReporter < CurationConcernReporter

    # Produce a report containing:
    # * # of datasets
    # * Total size of the datasets in GB
    # * # of unique depositors
    # * # of repeat depositors
    # * Top 10 file formats (csv, nc, txt, pdf, etc)
    # * Discipline of dataset
    # * Names of depositors
    #

    def initialize( rake_task: false, options: {} )
      super( rake_task: rake_task, options: options )
    end

    def run
      return if @options_error.present?
      initialize_report_values
      report
    end

    def report_email_subject
      "Works Report"
    end

    protected

      def report
        out_report << "Report server: #{::DeepBlueDocs::Application.config.hostname}" << "\n"
        report_timestamp_begin = Time.new
        out_report << "Report started: " << report_timestamp_begin.to_s << "\n"
        @prefix = "#{Time.now.strftime('%Y%m%d')}_works_report" if @prefix.nil? ## YYYYMMDD
        @works_file = Pathname.new( report_dir ).join "#{prefix}_works.csv"
        @file_sets_file = Pathname.new( report_dir ).join "#{prefix}_file_sets.csv"
        @out_works = File.open( works_file, 'w' )
        @out_file_sets = File.open( file_sets_file, 'w' )
        print_work_line( out_works, header: true )
        print_file_set_line( out_file_sets, header: true )

        process_works

        console_puts
        console_puts works_file
        console_puts file_sets_file

        # console_puts
        # console_puts JSON.pretty_generate( @totals )
        # console_puts
        # console_puts JSON.pretty_generate( @tagged_totals )
        # console_puts

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
