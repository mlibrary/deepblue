# frozen_string_literal: true

module Deepblue

  require_relative '../../tasks/deepblue/abstract_task'

  class CleanHyraxTmpDirService

    mattr_accessor :clean_hyrax_tmp_dir_service_debug_verbose, default: false

    attr_accessor :msg_handler
    attr_accessor :days_old

    def initialize( days_old: nil, msg_handler:, debug_verbose: clean_hyrax_tmp_dir_service_debug_verbose )
      debug_verbose = debug_verbose || clean_hyrax_tmp_dir_service_debug_verbose
      @msg_handler = msg_handler
      @msg_handler.debug_verbose = @msg_handler.debug_verbose || debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "days_old=#{days_old}",
                                             "msg_handler=#{msg_handler}",
                                             "" ] if debug_verbose
      @days_old = days_old
    end

    def report_du
      path = "#{base_dir}/."
      cmd = "du -sh #{path}"
      msg_handler.msg cmd
      rv = `#{cmd}`
      rv.chomp
    end

    def run_msg( msg )
      msg_handler.msg msg
    end

    def delete_dirs_glob_regexp( glob: '*', filename_regexp: nil, dotmatch: false )
      msg_handler.msg "delete dirs glob: #{glob} filename_regexp: #{filename_regexp}"
      ::Deepblue::DiskUtilitiesHelper.delete_dirs_glob_regexp( base_dir: base_dir,
                                                               days_old: older_than_days,
                                                               filename_regexp: filename_regexp,
                                                               glob: glob,
                                                               dotmatch: dotmatch,
                                                               msg_handler: msg_handler,
                                                               recursive: false )
    end

    # returns count of files deleted
    def delete_files_glob_regexp( glob: '*', filename_regexp: nil, dotmatch: false )
      ::Deepblue::DiskUtilitiesHelper.delete_files_glob_regexp( base_dir: base_dir,
                                                                days_old: older_than_days,
                                                                filename_regexp: filename_regexp,
                                                                glob: glob,
                                                                dotmatch: dotmatch,
                                                                msg_handler: msg_handler )
    end


  end

end
