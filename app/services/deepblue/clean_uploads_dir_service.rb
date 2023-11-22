# frozen_string_literal: true

module Deepblue

  require_relative '../../tasks/deepblue/abstract_task'

  class CleanUploadsDirService < CleanHyraxTmpDirService

    CLEAN_UPLOADS_DAYS_OLD_DEFAULT = 180

    mattr_accessor :clean_uploads_dir_service_debug_verbose, default: false

    attr_accessor :msg_handler, :days_old, :verbose

    def initialize( days_old: nil, msg_handler:, debug_verbose: clean_uploads_dir_service_debug_verbose )
      debug_verbose = debug_verbose || clean_uploads_dir_service_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "days_old=#{days_old}",
                                             "msg_handler=#{msg_handler}",
                                             "to_console=#{to_console}",
                                             "verbose=#{verbose}",
                                             "" ] if debug_verbose
      @days_old = days_old
      @msg_handler = msg_handler
      @msg_handler.debug_verbose = @msg_handler.debug_verbose || debug_verbose
    end

    def base_dir
      @base_dir ||= Pathname( ::Deepblue::DiskUtilitiesHelper.tmp_uploads_path )
    end

    def older_than_days
      @older_than_days ||= days_old.nil? ? CLEAN_UPLOADS_DAYS_OLD_DEFAULT : days_old
    end

    def run
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "base_dir=#{base_dir}",
                                             "msg_handler=#{msg_handler}",
                                             "older_than_days=#{older_than_days}",
                                             "" ] if msg_handler.debug_verbose
      report_prefix = "Uploads Dir Disk"
      msg_handler.msg "#{report_prefix} usage before: #{report_du}"
      delete_dirs_glob_regexp( glob: '[0-9]*/', filename_regexp: /^[0-9]+$/ )
      msg_handler.msg "#{report_prefix} usage after: #{report_du}"
    end

  end

end
