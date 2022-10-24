# frozen_string_literal: true

module Deepblue

  class GlobusStatus

    attr_reader :locked_ids
    attr_reader :error_ids
    attr_reader :prep_dir_ids
    attr_reader :prep_dir_tmp_ids
    attr_reader :ready_ids

    attr_reader :disk_usage

    attr_accessor :include_disk_usage
    attr_accessor :msg_handler
    attr_accessor :skip_ready

    attr_reader   :starts_with_prep_dir
    attr_reader   :starts_with_download_dir

    def initialize( include_disk_usage: true, msg_handler:, skip_ready: false )
      @msg_handler = msg_handler
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "include_disk_usage=#{include_disk_usage}",
                               "skip_ready=#{skip_ready}",
                               "" ] if msg_handler.debug_verbose
      @include_disk_usage = include_disk_usage
      @skip_ready = skip_ready
      @locked_ids = {}
      @error_ids = {}
      @prep_dir_ids = {}
      @prep_dir_tmp_ids = {}
      @ready_ids = {}
      @disk_usage = {}

      @base_name = GlobusJob.target_base_name ''
      @lock_file_prefix = GlobusJob.target_file_name_env(nil, 'lock', @base_name ).to_s
      @lock_file_re = Regexp.compile( '^' + @lock_file_prefix + '([0-9a-z-]+)' + '$' )
      @error_file_prefix = GlobusJob.target_file_name_env(nil, 'error', @base_name ).to_s
      @error_file_re = Regexp.compile( '^' + @error_file_prefix + '([0-9a-z-]+)' + '$' )
      @prep_dir_prefix = GlobusJob.target_file_name( nil, "#{GlobusJob.server_prefix(str: '_')}#{@base_name}" ).to_s
      @prep_dir_re = Regexp.compile( '^' + @prep_dir_prefix + '([0-9a-z-]+)' + '$' )
      @prep_tmp_dir_re = Regexp.compile( '^' + @prep_dir_prefix + '([0-9a-z-]+)_tmp' + '$' )
      @ready_file_prefix = GlobusJob.target_file_name_env(nil, 'ready', @base_name ).to_s
      @ready_file_re = Regexp.compile( '^' + @ready_file_prefix + '([0-9a-z-]+)' + '$' )
      @starts_with_prep_dir = "#{::Deepblue::GlobusIntegrationService.globus_prep_dir}#{File::SEPARATOR}"
      @starts_with_download_dir = "#{::Deepblue::GlobusIntegrationService.globus_download_dir}#{File::SEPARATOR}"
      msg_handler.msg_verbose [ msg_handler.here,
                               msg_handler.called_from,
                               "lock_file_prefix=#{@lock_file_prefix}",
                               "lock_file_re=#{@lock_file_re}",
                               "error_file_prefix=#{@error_file_prefix}",
                               "error_file_re=#{@error_file_re}",
                               "prep_dir_prefix=#{@prep_dir_prefix}",
                               "prep_dir_re=#{@prep_dir_re}",
                               "prep_tmp_dir_re=#{@prep_tmp_dir_re}",
                               "ready_file_prefix=#{@prep_dir_re}",
                               "ready_file_re=#{@prep_tmp_dir_re}",
                               "starts_with_prep_dir=#{@starts_with_prep_dir}",
                               "" ] if msg_handler.verbose
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "lock_file_prefix=#{@lock_file_prefix}",
                               "lock_file_re=#{@lock_file_re}",
                               "error_file_prefix=#{@error_file_prefix}",
                               "error_file_re=#{@error_file_re}",
                               "prep_dir_prefix=#{@prep_dir_prefix}",
                               "prep_dir_re=#{@prep_dir_re}",
                               "prep_tmp_dir_re=#{@prep_tmp_dir_re}",
                               "ready_file_prefix=#{@prep_dir_re}",
                               "ready_file_re=#{@prep_tmp_dir_re}",
                               "starts_with_prep_dir=#{@starts_with_prep_dir}",
                               "" ] if msg_handler.debug_verbose
      populate
    end

    def populate
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "" ]  if msg_handler.debug_verbose
      populate_from path: @starts_with_prep_dir
    end

    def populate_from( path: )
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "path=#{path}",
                               "" ]  if msg_handler.debug_verbose
      files = files( starts_with: path )
      files.each do |f|
        f1 = f
        f = f.slice( (path.length)..(f.length) ) if f.starts_with? path
        # msg_handler.msg_verbose [ msg_handler.here,
        #                          msg_handler.called_from,
        #                          "processing '#{f1}'",
        #                          "strip leading path '#{f}'",
        #                          "" ]  if msg_handler.verbose
        msg_handler.bold_debug [ msg_handler.here,
                                 msg_handler.called_from,
                                 "processing '#{f1}'",
                                 "strip leading path '#{f}'",
                                 "" ]  if msg_handler.debug_verbose
        add_locked_id( path: f )
        add_error_id( path: f )
        add_prep_dir_id( path: f )
        add_prep_dir_tmp_id( path: f )
        add_ready_id( path: f ) unless skip_ready
      end
    end

    def add_locked_id( path: )
      add_status( matcher: @lock_file_re, path: path, hash: @locked_ids, type: 'locked' )
    end

    def add_error_id( path: )
      add_status( matcher: @error_file_re, path: path, hash: @error_ids, type: 'error' )
    end

    def add_prep_dir_id( path: )
      add_status( matcher: @prep_dir_re, path: path, hash: @prep_dir_ids, type: 'prep' )
    end

    def add_prep_dir_tmp_id( path: )
      add_status( matcher: @prep_tmp_dir_re, path: path, hash:@prep_dir_tmp_ids, type: 'prep tmp' )
    end

    def add_ready_id( path: )
      return if skip_ready
      add_status( matcher: @ready_file_re, path: path, hash: @ready_ids, type: 'ready' )
    end

    def add_status( matcher:, path:, hash:, type: )
      match = matcher.match( path )
      return false unless match
      concern_id = match[1]
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "#{type} id #{concern_id}",
                               "" ] if msg_handler.debug_verbose
      hash[concern_id] = path
      add_disk_usage( path: path ) if include_disk_usage
      return true
    end

    def add_disk_usage( path: )
      return if @disk_usage.has_key? path

    end

    def report_du( path: )
      path = "#{base_dir}/."
      cmd = "du -sh #{path}"
      run_msg cmd
      rv = `#{cmd}`
      rv.chomp
    end

    def files( starts_with: )
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "starts_with=#{starts_with}",
                               "" ]  if msg_handler.debug_verbose
      rv = Dir.glob( "#{starts_with}*", File::FNM_DOTMATCH )
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "files.size=#{rv.size}",
                               "" ]  if msg_handler.debug_verbose
      return rv
    end

    def reporter
      @reporter ||= reporter_init
    end

    def reporter_init
      reporter = ::Deepblue::GlobusReporter.new( globus_status: self,
                                                 as_html: true,
                                                 msg_handler: msg_handler,
                                                 options: { 'quiet' => msg_handler.quiet } )
      reporter.run
      return reporter
    end

  end

end
