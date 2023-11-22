# frozen_string_literal: true

module Deepblue

  require_relative '../../tasks/deepblue/abstract_task'

  class CleanDerivativesDirService < CleanHyraxTmpDirService

    CLEAN_DERIVATIVES_DAYS_OLD_DEFAULT = 7

    mattr_accessor :clean_derivatives_dir_service_debug_verbose, default: false

    def initialize( days_old: nil, msg_handler:, debug_verbose: clean_derivatives_dir_service_debug_verbose )
      super
      debug_verbose = debug_verbose || clean_derivatives_dir_service_debug_verbose
      @msg_handler.debug_verbose = @msg_handler.debug_verbose || debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if debug_verbose
    end

    def base_dir
      @base_dir ||= Pathname( ::Deepblue::DiskUtilitiesHelper.tmp_derivatives_path )
    end

    def older_than_days
      @older_than_days ||= days_old.nil? ? CLEAN_DERIVATIVES_DAYS_OLD_DEFAULT : days_old
    end

    def run
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "base_dir=#{base_dir}",
                                             "msg_handler=#{msg_handler}",
                                             "older_than_days=#{older_than_days}",
                                             "" ] if msg_handler.debug_verbose
      report_prefix = "Derivative Dir Disk"
      msg_handler.msg "#{report_prefix} usage before: #{report_du}"
      delete_dirs_glob_regexp( glob: '[0-9a-z]{9}' )
      delete_dirs_glob_regexp( glob: "jna-*" )
      delete_dirs_glob_regexp( glob: "lu[a-z0-9]{1,4}*.tmp" )
      delete_files_glob_regexp( glob: "#{'?'*8}-#{'?'*3}*-*", filename_regexp: /^[0-9]{8}\-[0-9]{3,8}\-[0-9a-z]{3,7}$/ )
      delete_files_glob_regexp( glob: "apache-tika-[0-9]{1,5}*.tmp" )
      delete_files_glob_regexp( glob: "byteseek[0-9]{1,5}*.tmp" )
      delete_files_glob_regexp( glob: "down-net_http#{'?'*8}-#{'?'*3}*-*", filename_regexp: /^down\-net_http[0-9]{8}\-[0-9]{3,8}\-[0-9a-z]{3,7}$/ )
      delete_files_glob_regexp( glob: "magick-[0-9]{2}*" )
      delete_files_glob_regexp( glob: "mini_magick20*" )
      delete_files_glob_regexp( glob: "pfbox[0-9]{2}*" )
      delete_files_glob_regexp( glob: "puma20#{'?'*6}-*", filename_regexp: /^puma20[0-9]{6}\-.*$/ )
      delete_files_glob_regexp( glob: "open-uri20#{'?'*6}-*", filename_regexp: /^open-uri20[0-9]{6}\-.*$/ )
      delete_files_glob_regexp( glob: "RackMultipart20#{'?'*6}-*", filename_regexp: /^RackMultipart20[0-9]{6}\-.*$/ )
      delete_files_glob_regexp( glob: "'RAB*.tif'" )
      delete_files_glob_regexp( glob: ".~lock.*", dotmatch: true )
      delete_files_glob_regexp( glob: "*.pdf" )
      # *.jpg
      msg_handler.msg "#{report_prefix} usage after: #{report_du}"
    end

  end

end
