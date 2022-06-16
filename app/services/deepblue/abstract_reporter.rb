# frozen_string_literal: true

module Deepblue

  require_relative './abstract_service'
  require_relative './curation_concern_report_behavior'

  class AbstractReporter < AbstractService

    attr_accessor :as_html
    attr_accessor :quiet
    attr_accessor :debug_verbose
    attr_accessor :out

    def initialize( debug_verbose: false,
                    as_html: false, # TODO
                    msg_handler:,
                    options: {} )

      # TODO: ?? merge the keys from various hashes
      super( msg_handler: msg_handler, options: options )
      @as_html = as_html
      @debug_verbose = debug_verbose
      msg_handler.debug_verbose = @debug_verbose
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
      raise "Expected the #report method to be defined by descendent class."
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
      msg_handler.msg line
    end

    # def c_print( msg = "" )
    #   console_print msg
    # end

    # def c_puts( msg = "" )
    #   msg_handler.msg msg
    # end

  end

end
