# frozen_string_literal: true

module Deepblue

  require_relative './abstract_service'
  require_relative './curation_concern_report_behavior'

  class GlobusReporter < AbstractService

    attr_accessor :error_ids
    attr_accessor :locked_ids
    attr_accessor :prep_dir_ids
    attr_accessor :prep_dir_tmp_ids

    attr_accessor :out

    def initialize( error_ids: {},
                    locked_ids: {},
                    prep_dir_ids: {},
                    prep_dir_tmp_ids: {},
                    rake_task: false,
                    options: {} )

      # TODO: ?? merge the keys from various hashes
      super( rake_task: rake_task, options: options )
      # # TODO: @file_ext_re = TaskHelper.task_options_value( @options, key: 'file_ext_re', default_value: DEFAULT_FILE_EXT_RE )
      # report_file_prefix = task_options_value( key: 'report_file_prefix', default_value: DEFAULT_REPORT_FILE_PREFIX )
      # @prefix = expand_path_partials( report_file_prefix )
      # report_dir = task_options_value( key: 'report_dir', default_value: DEFAULT_REPORT_DIR )
      # @report_dir = expand_path_partials( report_dir )
      # @file_ext_re = DEFAULT_FILE_EXT_RE
      @error_ids = error_ids
      @locked_ids = locked_ids
      @prep_dir_ids = prep_dir_ids
      @prep_dir_tmp_ids = prep_dir_tmp_ids
    end

    def initialize_report_values
      @out ||= []
    end

    def run
      return if @options_error.present?
      initialize_report_values
      report
    end

    def report
      report_section( header: "Globus Works with Error Files:", hash: error_ids )
      report_section( header: "Globus Works with Lock Files:", hash: locked_ids )
      report_section( header: "Globus Works with Prep Dirs:", hash: prep_dir_ids )
      report_section( header: "Globus Works with Prep Tmp Dirs:", hash: prep_dir_tmp_ids )
    end

    def report_section( header:, hash: )
      r_puts( header )
      unless hash.present?
        r_puts "None."
      else
        hash.each_key do |id|
          r_puts id # TODO: put link to work
        end
      end
    end

    def r_puts( line = "" )
      out << line
      c_puts line if to_console
    end

    protected

      def c_print( msg = "" )
        console_print msg
      end

      def c_puts( msg = "" )
        console_puts msg
      end

  end

end
