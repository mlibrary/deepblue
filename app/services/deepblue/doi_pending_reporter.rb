# frozen_string_literal: true

module Deepblue

  require_relative './abstract_reporter'

  class DoiPendingReporter < AbstractReporter

    attr_accessor :data_set_ids
    attr_accessor :file_set_ids

    def initialize( data_set_ids: [],
                    file_set_ids: [],
                    quiet: true,
                    debug_verbose: false,
                    as_html: false, # TODO
                    rake_task: false )

      # TODO: ?? merge the keys from various hashes
      super( as_html: as_html, debug_verbose: debug_verbose, quiet: quiet, rake_task: rake_task, options: options )
      @data_set_ids = data_set_ids
      @file_set_ids = file_set_ids
    end

    def initialize_report_values
      super
      DoiMintingService.doi_pending_finder( data_set_ids_found: data_set_ids,
                                            file_set_ids_found: file_set_ids,
                                            rake_task: rake_task,
                                            debug_verbose: debug_verbose )
    end

    def report
      report_section_data_set( header: "Data sets with pending doi:", ids: data_set_ids )
      report_section_file_set( header: "File sets with pending doi:", ids: file_set_ids )
    end

    def report_section_data_set( header:, ids: )
      return if hash.nil?
      return if quiet && !hash.present?
      r_header( header )
      unless ids.present?
        r_line "None."
      else
        r_list_begin( 'ul' )
        ids.each_key do |id|
          r_list_item( ::Deepblue::EmailHelper.data_set_url( id: id ), as_link: true )
        end
        r_list_end( 'ul' )
      end
    end

    def report_section_file_set( header:, ids: )
      return if hash.nil?
      return if quiet && !hash.present?
      r_header( header )
      unless ids.present?
        r_line "None."
      else
        r_list_begin( 'ul' )
        ids.each_key do |id|
          r_list_item( ::Deepblue::EmailHelper.file_set_url( id: id ), as_link: true )
        end
        r_list_end( 'ul' )
      end
    end

  end

end
