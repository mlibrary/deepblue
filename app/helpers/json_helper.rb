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
        #when 0 then return "<table>\n<tr><td>&nbsp;</td></tr>\n</table>\n"
      when 0 then return "&nbsp;"
      when 1 then return "<table>\n<tr><td>#{key_values_to_table( key_values[0], parse: false )}</td></tr>\n</table>\n"
      else
        arr = key_values.map { |x| key_values_to_table( x, parse: false ) }
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
    elsif key_values.is_a? String
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "String",
                                             "" ] if json_helper_debug_verbose
      return "&nbsp;" if key_values.blank?
      arr = split_str_into_lines( key_values )
      return ERB::Util.html_escape( key_values ) if arr.size <= 1
      arr = arr.map { |x| ERB::Util.html_escape( x ) }
      return "#{arr.join("<br/>")}"
    elsif key_values.nil?
      return "&nbsp;"
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

  def self.split_str_into_lines( str )
    arr = str.split( /[\r\n]+/ )
    return arr if arr.size > 1
    str.split( /(?:\\n|\\r)+/ )
  end

end
