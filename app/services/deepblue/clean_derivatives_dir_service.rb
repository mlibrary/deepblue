# frozen_string_literal: true

module Deepblue

  require 'tasks/abstract_task'

  class CleanDerivativesDirService

    CLEAN_DERIVATIVES_DAYS_OLD_DEFAULT = 7

    mattr_accessor :clean_derivatives_dir_service_debug_verbose, default: false

    attr_accessor :msg_handler, :days_old, :verbose

    def initialize( days_old: nil,
                    msg_handler: nil,
                    to_console: false,
                    verbose: false,
                    debug_verbose: clean_derivatives_dir_service_debug_verbose )

      debug_verbose = debug_verbose || clean_derivatives_dir_service_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "days_old=#{days_old}",
                                             "msg_handler=#{msg_handler}",
                                             "to_console=#{to_console}",
                                             "verbose=#{verbose}",
                                             "" ] if debug_verbose
      @days_old = days_old
      @msg_handler = msg_handler
      @msg_handler ||= ::Deepblue::MessageHandler.new( debug_verbose: debug_verbose,
                                                       to_console: to_console,
                                                       verbose: verbose )
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
                                             "to_console=#{msg_handler.to_console}",
                                             "verbose=#{msg_handler.verbose}",
                                             "" ] if msg_handler.debug_verbose

      msg_handler.msg "Disk usage before: #{report_du}"
      delete_dirs_glob_regexp( glob: '?' * 9, filename_regexp: /^[0-9a-z]{9}$/ )
      delete_files_glob_regexp( glob: "#{'?'*8}-#{'?'*3}*-*", filename_regexp: /^[0-9]{8}\-[0-9]{3,6}\-[0-9a-z]{3,7}$/ )
      delete_files_glob_regexp( glob: "puma20#{'?'*6}-*", filename_regexp: /^puma20[0-9]{6}\-.*$/ )
      delete_files_glob_regexp( glob: "open-uri20#{'?'*6}-*", filename_regexp: /^open-uri20[0-9]{6}\-.*$/ )
      delete_files_glob_regexp( glob: "RackMultipart20#{'?'*6}-*", filename_regexp: /^RackMultipart20[0-9]{6}\-.*$/ )
      delete_files_glob_regexp( glob: "mini_magick20*" )
      delete_files_glob_regexp( glob: "apache-tika-*.tmp" )
      # byteseek1311965235160555757.tmp
      delete_files_glob_regexp( glob: "*.pdf" )
      # *.jpg
      msg_handler.msg "Disk usage after: #{report_du}"
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
      # ::Deepblue::LoggingHelper.debug msg
      # puts msg if @to_console
      # @job_msg_queue << msg unless @job_msg_queue.nil?
    end

    def delete_dirs_glob_regexp( glob: '*', filename_regexp: nil )
      msg_handler.msg "delete dirs glob: #{glob} filename_regexp: #{filename_regexp}"
      ::Deepblue::DiskUtilitiesHelper.delete_dirs_glob_regexp( base_dir: base_dir,
                                                               days_old: older_than_days,
                                                               filename_regexp: filename_regexp,
                                                               glob: glob,
                                                               msg_queue: msg_handler.msg_queue,
                                                               recursive: false,
                                                               verbose: msg_handler.verbose )
    end

    # returns count of files deleted
    def delete_files_glob_regexp( glob: '*', filename_regexp: nil )
      ::Deepblue::DiskUtilitiesHelper.delete_files_glob_regexp( base_dir: base_dir,
                                                                days_old: older_than_days,
                                                                filename_regexp: filename_regexp,
                                                                glob: glob,
                                                                msg_queue: msg_handler.msg_queue,
                                                                verbose: msg_handler.verbose )
    end


  end

end
