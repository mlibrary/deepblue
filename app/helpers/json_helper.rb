# frozen_string_literal: true

module JsonHelper

  require 'json'

  mattr_accessor :json_helper_debug_verbose, default: false

  def self.key_values_to_table( key_values, parse: false )
    key_values = JSON.parse( key_values ) if parse
    if key_values.is_a? Array
      case key_values.size
      when 0 then return "<table>\n<tr><td>&nbsp;</td></tr>\n</table>\n"
      when 1 then return "<table>\n<tr><td>#{ERB::Util.html_escape( key_values[0] )}</td></tr>\n</table>\n"
      else
        arr = key_values.map { |x| key_values_to_table( x ) }
        return "<table>\n<tr><td>#{arr.join("</td></tr>\n<tr><td>")}</td></tr>\n</table>\n"
      end
    elsif key_values.is_a? Hash
      rv = "<table>\n"
      key_values.each_pair do |key,value|
        rv += "<tr><td>#{ERB::Util.html_escape( key )}</td><td>#{key_values_to_table( value )}</td></tr>\n"
      end
      rv += "</table>\n"
      return rv
    else
      return ERB::Util.html_escape( key_values )
    end
  end

  def self.pp_key_values( raw_key_values )
    return JSON.pretty_generate( JSON.parse( raw_key_values ) )
  end

end
