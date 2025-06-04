# frozen_string_literal: true

module Deepblue

  require_relative './abstract_reporter'

  class TicketPendingReporter < AbstractReporter

    attr_accessor :data_set_ids
    attr_accessor :include_blank_tickets
    attr_accessor :include_published_works

    def initialize( data_set_ids: [],
                    msg_handler:,
                    as_html: false,
                    options: {} )

      super( as_html: as_html, msg_handler: msg_handler, options: options )
      @include_blank_tickets = false
      @include_published_works = false
      @data_set_ids = data_set_ids
    end

    def initialize_report_values
      super
      ticket_pending_finder( data_set_ids_found: data_set_ids,
                                               msg_handler: msg_handler,
                                               debug_verbose: debug_verbose )
    end

    def report
      report_section_data_set( header: "Data sets with pending tickets:", ids: data_set_ids )
    end

    def report_section_data_set( header:, ids: )
      r_header( header )
      unless ids.present?
        r_line "None."
      else
        r_list_begin( 'ul' )
        ids.each do |id|
          r_list_item( ::Deepblue::EmailHelper.data_set_url( id: id ), as_link: true )
        end
        r_list_end( 'ul' )
      end
    end

    def ticket_pending_finder( data_set_ids_found:, msg_handler:, debug_verbose: )
      msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                               ::Deepblue::LoggingHelper.called_from,
                               "data_set_ids_found.is_a? Array=#{data_set_ids_found.is_a? Array}",
                               "msg_handler=#{msg_handler}",
                               "" ] if debug_verbose

      if data_set_ids_found.is_a? Array
        use_solr = true
        all_data_sets( solr: use_solr ).each do |work|
          if use_solr
            ticket = work['ticket_tesim']
            ticket = ticket.first if ticket.is_a? Array
            # data_set_ids_found << work['id'] if ::Deepblue::TicketHelper.ticket_pending?( ticket: ticket )
            if ticket.blank?
              data_set_ids_found << work['id'] if @include_blank_tickets
              next
            end
            data_set_ids_found << work['id'] unless ticket.start_with?( "https:" )
          else
            ticket = work.ticket
            if ticket.blank?
              data_set_ids_found << work.id if @include_blank_tickets
              next
            end
            data_set_ids_found << work.id unless ticket.start_with?( "https:" )
          end
        end
      end

    end

  end

end
