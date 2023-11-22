# frozen_string_literal: true

module Deepblue

  require_relative '../../app/tasks/deepblue/abstract_task'
  require_relative '../../app/services/deepblue/curation_concern_report_behavior'

  class CurationConcernReportTask < AbstractTask

    include ::Deepblue::CurationConcernReportBehavior

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
      # TODO: @file_ext_re = TaskHelper.task_options_value( @options, key: 'file_ext_re', default_value: DEFAULT_FILE_EXT_RE )
      @prefix = task_options_value( key: 'report_file_prefix', default_value: DEFAULT_REPORT_FILE_PREFIX )
      @report_dir = task_options_value( key: 'report_dir', default_value: DEFAULT_REPORT_DIR )
      @file_ext_re = DEFAULT_FILE_EXT_RE
    end

  end

end
