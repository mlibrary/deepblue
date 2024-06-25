# frozen_string_literal: true

require_relative './abstract_cleanup_task'

module Aptrust

  class CleanupAllTask < ::Aptrust::AbstractCleanupTask

    attr_accessor :bag_id_for_noid
    attr_accessor :cleanup_noids

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
      @cleanup_noids = {}
    end

    def add_noid_from_filename( file: )
      msg_handler.msg_verbose "file=#{file}"
      if @test_date_begin.present?
        timestamp =  File.mtime file
        # msg_handler.msg_verbose "timestamp: #{timestamp}"
        # msg_handler.msg_verbose "@test_date_begin: #{@test_date_begin}"
        # msg_handler.msg_verbose "@test_date_end: #{@test_date_end}"
        # msg_handler.msg_verbose "@test_date_begin <= timestamp && timestamp <= @test_date_end=#{@test_date_begin <= timestamp && timestamp <= @test_date_end}"
        return unless @test_date_begin <= timestamp && timestamp <= @test_date_end
      end
      match = @bag_id_regexp.match File.basename file
      return unless match
      noid = match[1]
      msg_handler.msg_verbose "noid found #{noid}"
      @cleanup_noids[noid] = true
    end

    def bag_id_regexp( bag_id: )
      re = Regexp.escape bag_id
      re.gsub!( 'noid', '([^.]+)' )
      re = Regexp.compile( re )
      return re
    end

    def find_noids_from_file_system
      msg_handler.msg_verbose "working_dir=#{working_dir}"
      @bag_id_for_noid = bag_id( noid: 'noid' )
      bag_id_glob = bag_id_for_noid.gsub( 'noid', '*' )
      @bag_id_regexp = bag_id_regexp( bag_id: @bag_id_for_noid )
      msg_handler.msg_verbose "bag_id_glob=#{bag_id_glob}"
      files = ::Deepblue::DiskUtilitiesHelper.files_in_dir( dir_path: working_dir,
                                                            glob: bag_id_glob,
                                                            dotmatch: false,
                                                            include_dirs: true,
                                                            msg_handler: msg_handler,
                                                            test_mode: false )
      test_dates_init if date_begin.present? || date_end.present?
      files.each { |file| add_noid_from_filename( file: file )  }
      msg_handler.msg_verbose @cleanup_noids.pretty_inspect
    end

    def run
      msg_handler.msg_verbose "Starting..."
      # msg_handler.msg_verbose "debug_verbose=#{debug_verbose}"
      find_noids_from_file_system
      @cleanup_noids.each { |noid,_v| cleanup_by_noid( noid: noid ) }
      msg_handler.msg_verbose "Finished."
      run_email_targets( subject: 'Aptrust::CleanupAllTask', event: 'CleanupAllTask' )
    end

  end

end
