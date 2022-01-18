# frozen_string_literal: true

module JsonHelper

  require 'json'

  mattr_accessor :json_helper_debug_verbose, default: false

  def self.key_values_to_table( key_values, parse: false )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "key_values.class.name=#{key_values.class.name}",
                                           "key_values=#{key_values}",
                                           "parse=#{parse}",
                                           "" ] if json_helper_debug_verbose
    key_values = JSON.parse( key_values ) if parse && key_values.is_a?( String )
    if key_values.is_a? Array
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "array",
                                             "" ] if json_helper_debug_verbose
      case key_values.size
      when 0 then return "<table>\n<tr><td>&nbsp;</td></tr>\n</table>\n"
      when 1 then return "<table>\n<tr><td>#{ERB::Util.html_escape( key_values[0] )}</td></tr>\n</table>\n"
      else
        arr = key_values.map { |x| key_values_to_table( x ) }
        return "<table>\n<tr><td>#{arr.join("</td></tr>\n<tr><td>")}</td></tr>\n</table>\n"
      end
    elsif key_values.is_a? Hash
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "hash",
                                             "" ] if json_helper_debug_verbose
      rv = "<table>\n"
      key_values.each_pair do |key,value|
        rv += "<tr><td>#{ERB::Util.html_escape( key )}</td><td>#{key_values_to_table( value, parse: false )}</td></tr>\n"
      end
      rv += "</table>\n"
      return rv
    else
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "default",
                                             "" ] if json_helper_debug_verbose
      return ERB::Util.html_escape( key_values.to_s )
    end
  end

  def self.pp_key_values( raw_key_values )
    return JSON.pretty_generate( JSON.parse( raw_key_values ) )
  end

end
