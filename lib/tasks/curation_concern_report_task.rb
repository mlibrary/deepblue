# frozen_string_literal: true

module Deepblue

  require 'tasks/abstract_task'
  require_relative '../../app/services/deepblue/curation_concern_report_behavior'

  class CurationConcernReportTask < AbstractTask

    include ::Deepblue::CurationConcernReportBehavior

    def initialize( options: {} )
      super( options: options )
      # TODO: @file_ext_re = TaskHelper.task_options_value( @options, key: 'file_ext_re', default_value: DEFAULT_FILE_EXT_RE )
      @prefix = task_options_value( key: 'report_file_prefix', default_value: DEFAULT_REPORT_FILE_PREFIX )
      @report_dir = task_options_value( key: 'report_dir', default_value: DEFAULT_REPORT_DIR )
      @file_ext_re = DEFAULT_FILE_EXT_RE
    end

    protected

      def c_print( msg = "" )
        print msg
        STDOUT.flush
      end

      def c_puts( msg = "" )
        puts msg
      end

  end

end
