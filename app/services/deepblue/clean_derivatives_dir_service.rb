# frozen_string_literal: true

module Deepblue

  require 'tasks/abstract_task'

  class CleanDerivativesDirService

    CLEAN_DERIVATIVES_DAYS_OLD_DEFAULT = 7

    mattr_accessor :clean_derivatives_dir_service_debug_verbose, default: false

    attr_accessor :debug_verbose, :job_msg_queue, :days_old, :to_console, :verbose

    def initialize( days_old: nil,
                    job_msg_queue: [],
                    to_console: false,
                    verbose: false,
                    debug_verbose: clean_derivatives_dir_service_debug_verbose )

      @debug_verbose = debug_verbose || clean_derivatives_dir_service_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "days_old=#{days_old}",
                                             "job_msg_queue=#{job_msg_queue}",
                                             "to_console=#{to_console}",
                                             "verbose=#{verbose}",
                                             "" ] if debug_verbose
      @days_old = days_old
      @job_msg_queue = job_msg_queue
      @to_console = to_console
      @verbose = verbose
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
                                             "job_msg_queue=#{job_msg_queue}",
                                             "older_than_days=#{older_than_days}",
                                             "to_console=#{to_console}",
                                             "verbose=#{verbose}",
                                             "" ] if debug_verbose

      run_msg "Disk usage before: #{report_du}"
      delete_dirs_glob_regexp( glob: '?' * 9, filename_regexp: /^[0-9a-z]{9}$/ )
      delete_files_glob_regexp( glob: "#{'?'*8}-#{'?'*3}*-*", filename_regexp: /^[0-9]{8}\-[0-9]{3,6}\-[0-9a-z]{3,7}$/ )
      delete_files_glob_regexp( glob: "puma20#{'?'*6}-*", filename_regexp: /^puma20[0-9]{6}\-.*$/ )
      delete_files_glob_regexp( glob: "open-uri20#{'?'*6}-*", filename_regexp: /^open-uri20[0-9]{6}\-.*$/ )
      delete_files_glob_regexp( glob: "RackMultipart20#{'?'*6}-*", filename_regexp: /^RackMultipart20[0-9]{6}\-.*$/ )
      delete_files_glob_regexp( glob: "mini_magick20*" )
      delete_files_glob_regexp( glob: "apache-tika-*.tmp" )
      delete_files_glob_regexp( glob: "*.pdf" )
      run_msg "Disk usage after: #{report_du}"
    end

    def report_du
      path = "#{base_dir}/."
      cmd = "du -sh #{path}"
      run_msg cmd
      rv = `#{cmd}`
      rv.chomp
    end

    def run_msg( msg )
      ::Deepblue::LoggingHelper.debug msg
      puts msg if @to_console
      @job_msg_queue << msg unless @job_msg_queue.nil?
    end

    def delete_dirs_glob_regexp( glob: '*', filename_regexp: nil )
      run_msg "delete dirs glob: #{glob} filename_regexp: #{filename_regexp}"
      ::Deepblue::DiskUtilitiesHelper.delete_dirs_glob_regexp( base_dir: base_dir,
                                                               days_old: older_than_days,
                                                               filename_regexp: filename_regexp,
                                                               glob: glob,
                                                               msg_queue: job_msg_queue,
                                                               recursive: false,
                                                               verbose: verbose )
    end

    # returns count of files deleted
    def delete_files_glob_regexp( glob: '*', filename_regexp: nil )
      ::Deepblue::DiskUtilitiesHelper.delete_files_glob_regexp( base_dir: base_dir,
                                                                days_old: older_than_days,
                                                                filename_regexp: filename_regexp,
                                                                glob: glob,
                                                                msg_queue: job_msg_queue,
                                                                verbose: verbose )
    end


  end

end
