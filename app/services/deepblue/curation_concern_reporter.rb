# frozen_string_literal: true

module Deepblue

  require_relative './abstract_service'
  require_relative './curation_concern_report_behavior'

  class CurationConcernReporter < AbstractService

    include ::Deepblue::CurationConcernReportBehavior

    def initialize( msg_handler:, options: {} )
      super( msg_handler: msg_handler, options: options )
      # TODO: @file_ext_re = TaskHelper.task_options_value( @options, key: 'file_ext_re', default_value: DEFAULT_FILE_EXT_RE )
      report_file_prefix = task_options_value( key: 'report_file_prefix', default_value: DEFAULT_REPORT_FILE_PREFIX )
      @prefix = expand_path_partials( report_file_prefix )
      report_dir = task_options_value( key: 'report_dir', default_value: DEFAULT_REPORT_DIR )
      @report_dir = expand_path_partials( report_dir )
      @file_ext_re = DEFAULT_FILE_EXT_RE
      @report_options ||= {}
      @report_options[:expanded_file_set_report] = task_options_value( key: :expanded_file_set_report, default_value: false )
    end

  end

end
