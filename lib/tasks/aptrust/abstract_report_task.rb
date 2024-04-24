# frozen_string_literal: true

require_relative './abstract_task'
require_relative '../../../app/helpers/deepblue/report_helper'

module Aptrust

  class AbstractReportTask < ::Aptrust::AbstractTask

    attr_accessor :report_append
    attr_accessor :report_file
    attr_accessor :report_dir
    attr_accessor :report_out
    attr_accessor :csv_out

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
      @report_append = option_value( key: 'report_append', default_value: false )
      @report_dir = option_value( key: 'report_dir', default_value: './data' )
      @report_file = report_file_init
    end

    def csv_out
      @csv_out ||= csv_out_init
    end

    def csv_out_init
      rv = CSV.open( report_file, 'wa', {:force_quotes=>true} ) if report_append
      rv = CSV.open( report_file, 'w', {:force_quotes=>true} ) unless report_append
      return rv
    end

    def report_file_init
      @report_file = option_value( key: 'report_file', default_value: nil )
      return if @report_file.blank?
      @report_file = ::Deepblue::ReportHelper.expand_path_partials @report_file
      @report_file = File.absolute_path @report_file
    end

    def report_out
      @report_out ||= report_out_init
    end

    def report_out_init
      rv = File.open( report_file, 'wa' ) if report_append
      rv = File.open( report_file, 'w' ) unless report_append
      return rv
    end

  end

end
