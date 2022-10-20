# frozen_string_literal: true

module Deepblue

  class GlobusStatus
    attr_reader :msg_handler
    attr_reader :locked_ids
    attr_reader :error_ids
    attr_reader :prep_dir_ids
    attr_reader :prep_dir_tmp_ids
    attr_reader :ready_ids

    attr_reader :skip_ready
    attr_reader :starts_with_path

    def initialize( msg_handler:, skip_ready: false )
      @msg_handler = msg_handler
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "skip_ready=#{skip_ready}",
                               "" ] if msg_handler.debug_verbose
      @skip_ready = skip_ready
      @locked_ids = {}
      @error_ids = {}
      @prep_dir_ids = {}
      @prep_dir_tmp_ids = {}
      @ready_ids = {}

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
      @starts_with_path = "#{::Deepblue::GlobusIntegrationService.globus_prep_dir}#{File::SEPARATOR}"
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
                               "starts_with_path=#{@starts_with_path}",
                               "" ] if msg_handler.debug_verbose
      populate
    end

    def populate
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "" ]  if msg_handler.debug_verbose
      files.each do |f|
        f1 = f
        f = f.slice( (@starts_with_path.length)..(f.length) ) if f.starts_with? @starts_with_path
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
      hash[concern_id] = true
      return true
    end

    def files
      rv = Dir.glob( "#{@starts_with_path}*", File::FNM_DOTMATCH )
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
      reporter = ::Deepblue::GlobusReporter.new( error_ids: @error_ids,
                                                 locked_ids: @locked_ids,
                                                 prep_dir_ids: @prep_dir_ids,
                                                 prep_dir_tmp_ids: @prep_dir_tmp_ids,
                                                 ready_ids: skip_ready ? nil : @ready_ids,
                                                 debug_verbose: msg_handler.debug_verbose,
                                                 as_html: true,
                                                 msg_handler: msg_handler,
                                                 options: { 'quiet' => msg_handler.quiet } )
      reporter.run
      return reporter
    end

  end

end
