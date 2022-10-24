# frozen_string_literal: true

module Deepblue

  require_relative './abstract_reporter'

  class GlobusReporter < AbstractReporter

    attr_accessor :globus_status

    def initialize( globus_status:, msg_handler:, as_html: false, options: {} )
      super( msg_handler: msg_handler, as_html: as_html, options: options )
      @globus_status = globus_status
    end

    def report
      report_section( header: "Globus Works with Error Files:", hash: @globus_status.error_ids )
      report_section( header: "Globus Works with Lock Files:", hash: @globus_status.locked_ids )
      report_section( header: "Globus Works with Prep Dirs:", hash: @globus_status.prep_dir_ids )
      report_section( header: "Globus Works with Prep Tmp Dirs:", hash: @globus_status.prep_dir_tmp_ids )
      report_section( header: "Globus Works Ready:", hash: @globus_status.ready_ids ) unless @globus_status.skip_ready
    end

    def report_section( header:, hash: )
      return if hash.nil?
      return if quiet && !hash.present?
      r_header( header )
      unless hash.present?
        r_line "None."
      else
        r_list_begin( 'ul' )
        hash.each_pair do |id, path|
          r_list_item( ::Deepblue::EmailHelper.data_set_url( id: id ), as_link: true )
          r_list_item( path ) if globus_status.include_disk_usage
          r_list_item( globus_status.disk_usage[path] ) if globus_status.include_disk_usage
        end
        r_list_end( 'ul' )
      end
    end

  end

end
