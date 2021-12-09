# frozen_string_literal: true

module Deepblue

  require_relative './abstract_service'
  require_relative './curation_concern_report_behavior'

  class GlobusReporter < AbstractService

    attr_accessor :as_html
    attr_accessor :error_ids
    attr_accessor :locked_ids
    attr_accessor :prep_dir_ids
    attr_accessor :prep_dir_tmp_ids
    attr_accessor :ready_ids
    attr_accessor :quiet
    attr_accessor :debug_verbose

    attr_accessor :out

    def initialize( error_ids: {},
                    locked_ids: {},
                    prep_dir_ids: {},
                    prep_dir_tmp_ids: {},
                    ready_ids: {},
                    quiet: true,
                    debug_verbose: false,
                    as_html: false, # TODO
                    rake_task: false )

      # TODO: ?? merge the keys from various hashes
      super( rake_task: rake_task, options: options )
      @error_ids = error_ids
      @locked_ids = locked_ids
      @prep_dir_ids = prep_dir_ids
      @prep_dir_tmp_ids = prep_dir_tmp_ids
      @ready_ids = ready_ids
      @quiet = quiet
      @as_html = as_html
      @debug_verbose = debug_verbose
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
      report_section( header: "Globus Works Ready:", hash: ready_ids )
    end

    def report_section( header:, hash: )
      return if quiet && !hash.present?
      r_header( header )
      unless hash.present?
        r_puts "None."
      else
        r_list_begin( 'ul' )
        hash.each_key do |id|
          r_list_item( ::Deepblue::EmailHelper.data_set_url( id: id ), as_link: true )
        end
        r_list_end( 'ul' )
      end
    end

    def r_header( header )
      if as_html
        r_puts( "<em>#{header}</em><br/>" )
      else
        r_puts( header )
      end
    end

    def r_line( line )
      if as_html
        r_puts( "#{line}<br/>" )
      else
        r_puts( line )
      end
    end

    def r_list_begin( list_type )
      if as_html
        r_puts( "<#{list_type}>" )
      end
    end

    def r_list_end( list_type )
      if as_html
        r_puts( "</#{list_type}>" )
      end
    end

    def r_list_item( item, as_link: false )
      if as_html
        if as_link
          r_puts( "<li><a href=\"#{item}\"></a>#{item}</li>" )
        else
          r_puts( "<li>#{item}</li>" )
        end
      else
        r_puts( item )
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
