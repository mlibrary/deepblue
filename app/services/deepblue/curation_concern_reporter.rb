# frozen_string_literal: true

module Deepblue

  require_relative './abstract_service'
  require_relative './curation_concern_report_behavior'

  class CurationConcernReporter < AbstractService

    include ::Deepblue::CurationConcernReportBehavior

    def initialize( msg_handler: nil, rake_task: false, options: {} )
      super( msg_handler: msg_handler, rake_task: rake_task, options: options )
      # TODO: @file_ext_re = TaskHelper.task_options_value( @options, key: 'file_ext_re', default_value: DEFAULT_FILE_EXT_RE )
      report_file_prefix = task_options_value( key: 'report_file_prefix', default_value: DEFAULT_REPORT_FILE_PREFIX )
      @prefix = expand_path_partials( report_file_prefix )
      report_dir = task_options_value( key: 'report_dir', default_value: DEFAULT_REPORT_DIR )
      @report_dir = expand_path_partials( report_dir )
      @file_ext_re = DEFAULT_FILE_EXT_RE
    end

    protected

      def c_print( msg = "" )
        console_print msg
      end

      def c_puts( msg = "" )
        console_puts msg
      end

  end

end
