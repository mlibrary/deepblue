# frozen_string_literal: true

module Deepblue

  require_relative './abstract_reporter'

  class GlobusReporter < AbstractReporter

    attr_accessor :error_ids
    attr_accessor :locked_ids
    attr_accessor :prep_dir_ids
    attr_accessor :prep_dir_tmp_ids
    attr_accessor :ready_ids

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
      super( as_html: as_html, debug_verbose: debug_verbose, quiet: quiet, rake_task: rake_task, options: options )
      @error_ids = error_ids
      @locked_ids = locked_ids
      @prep_dir_ids = prep_dir_ids
      @prep_dir_tmp_ids = prep_dir_tmp_ids
      @ready_ids = ready_ids
    end

    def report
      report_section( header: "Globus Works with Error Files:", hash: error_ids )
      report_section( header: "Globus Works with Lock Files:", hash: locked_ids )
      report_section( header: "Globus Works with Prep Dirs:", hash: prep_dir_ids )
      report_section( header: "Globus Works with Prep Tmp Dirs:", hash: prep_dir_tmp_ids )
      report_section( header: "Globus Works Ready:", hash: ready_ids )
    end

    def report_section( header:, hash: )
      return if hash.nil?
      return if quiet && !hash.present?
      r_header( header )
      unless hash.present?
        r_line "None."
      else
        r_list_begin( 'ul' )
        hash.each_key do |id|
          r_list_item( ::Deepblue::EmailHelper.data_set_url( id: id ), as_link: true )
        end
        r_list_end( 'ul' )
      end
    end

  end

end
