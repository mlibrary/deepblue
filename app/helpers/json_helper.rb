# frozen_string_literal: true

module JsonHelper

  require 'json'

  CSS_LOG_KEY_NAME = 'log-key-name'.freeze unless const_defined? :CSS_LOG_KEY_NAME

  mattr_accessor :json_helper_debug_verbose, default: false

  def self.css( add:, tag:, depth:, css: [] )
    return "" unless add
    return " class=\"log-#{tag}-#{depth}\"" if css.blank?
    return " class=\"log-#{tag}-#{depth} #{css.join(' ')}\""
  end

  def self.css_table( add:, depth:, css: [] )
    css( add: add, tag: 'table', depth: depth, css: css )
  end

  def self.css_td( add:, depth:, css: [] )
    css( add: add, tag: 'td', depth: depth, css: css )
  end

  def self.css_td_key( add:, depth:, css: [CSS_LOG_KEY_NAME] )
    css( add: add, tag: 'td', depth: depth, css: css )
  end

  def self.css_tr( add:, depth:, css: [] )
    css( add: add, tag: 'tr', depth: depth, css: css )
  end

  def self.find_hash_containing_key_value( key_values, depth: 0, key:, value:, debug_verbose: json_helper_debug_verbose )
    debug_verbose = debug_verbose || json_helper_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "key_values.class.name=#{key_values.class.name}",
                                           "key_values=#{key_values}",
                                           "depth=#{depth}",
                                           "key=#{key}",
                                           "value=#{value}",
                                           "" ] if debug_verbose
    if depth < 1 && key_values.is_a?( String )
      key_values = JSON.parse( key_values )
    end
    if key_values.is_a? Array
       key_values.each do |x|
         next unless ( x.is_a?( Hash ) || x.is_a?( Array ) )
         return find_hash_containing_key_value( x, depth: depth+1, key: key, value: value, debug_verbose: debug_verbose )
      end
    elsif key_values.is_a? Hash
       key_values.each_pair do |k,v|
        return key_values if k == key && v == value
        next unless ( v.is_a?( Hash ) || v.is_a?( Array ) )
        return find_hash_containing_key_value( v, depth: depth+1, key: key, value: value, debug_verbose: debug_verbose )
      end
    elsif key_values.is_a? Numeric
      return nil
    elsif [true, false].include? key_values
      return false
    elsif key_values.nil?
      return nil
    else
      return nil
    end
  end

  def self.find_in( log_entries, predicate:, debug_verbose: json_helper_debug_verbose )
    # example predicate
    # predicate = ->( log_entry ) { log_entry.is?( Hash ) && log_entry[:key] == value }
    debug_verbose = debug_verbose || json_helper_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "predicate.present?=#{predicate.present?}",
                                           "log_entries.class.name=#{log_entries.class.name}",
                                           "log_entries=#{log_entries}",
                                           "" ] if debug_verbose
    arr = Array( log_entries )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "arr.size=#{arr.size}",
                                           "" ] if debug_verbose
    arr.each do |log_entry|
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "log_entry=#{log_entry}",
                                             "log_entry.class.name=#{log_entry.class.name}",
                                             "" ] if debug_verbose
      entry = ::Deepblue::LogFileHelper.log_parse_entry log_entry
      return entry if predicate.call( entry )
    end
    return nil
  end

  def self.key_values_to_table( key_values,
                                depth: 0,
                                on_key_values_to_table_body_callback: nil,
                                parse: false,
                                row_key_value_callback: nil,
                                add_css: true,
                                debug_verbose: json_helper_debug_verbose )

    debug_verbose = debug_verbose || json_helper_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "key_values.class.name=#{key_values.class.name}",
                                           "key_values=#{key_values}",
                                           "depth=#{depth}",
                                           "parse=#{parse}",
                                           "on_key_values_to_table_body_callback.nil?=#{on_key_values_to_table_body_callback.nil?}",
                                           "add_css=#{add_css}",
                                           "row_key_value_callback.nil?=#{row_key_value_callback.nil?}",
                                           "" ] if debug_verbose
    if key_values.is_a? String
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                         ::Deepblue::LoggingHelper.called_from,
                                         "String",
                                         "" ] if debug_verbose
      return key_values_to_table_string( key_values,
                                         depth: depth, # depth+1?
                                         on_key_values_to_table_body_callback: on_key_values_to_table_body_callback,
                                         parse: parse,
                                         row_key_value_callback: row_key_value_callback,
                                         add_css: add_css,
                                         debug_verbose: debug_verbose )
    elsif key_values.is_a? Array
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "array",
                                             "" ] if debug_verbose
      case key_values.size
      when 0 then return "&nbsp;"
      when 1
        table = key_values_to_table( key_values[0],
                                     depth: depth + 1,
                                     on_key_values_to_table_body_callback: on_key_values_to_table_body_callback,
                                     parse: false,
                                     row_key_value_callback: row_key_value_callback,
                                     add_css: add_css,
                                     debug_verbose: debug_verbose )
        table_body = on_key_values_to_table_body_callback.call( depth, table ) if on_key_values_to_table_body_callback.present?
        if table_body.blank?
          css_tr = css_tr( add: add_css, depth: depth )
          css_td = css_td_key( add: add_css, depth: depth )
          table_body = "<tr#{css_tr}><td#{css_td}>#{table}</td></tr>\n"
        end
        return "<table#{css_table( add: add_css, depth: depth )}>\n#{table_body}</table>\n"
      else
        arr = key_values.map { |x| key_values_to_table( x,
                                          depth: depth + 1,
                                          on_key_values_to_table_body_callback: on_key_values_to_table_body_callback,
                                          parse: false,
                                          row_key_value_callback: row_key_value_callback,
                                          add_css: add_css,
                                          debug_verbose: debug_verbose ) }
        table_body = on_key_values_to_table_body_callback.call( depth, arr ) if on_key_values_to_table_body_callback.present?
        css_tr = css_tr( add: add_css, depth: depth )
        css_td = css_td_key( add: add_css, depth: depth )
        css_td2 = css_td( add: add_css, depth: depth )
        arr_join = "</td></tr>\n<tr#{css_tr}><td#{css_td2}>"
        table_body ||= "<tr#{css_tr}><td#{css_td}>#{arr.join(arr_join)}</td></tr>\n"
        return "<table#{css_table( add: add_css, depth: depth )}>\n#{table_body}</table>\n"
      end
    elsif key_values.is_a? Hash
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "hash",
                                             "" ] if debug_verbose
      rv = ""
      row_index = 0
      key_values.each_pair do |key,value|
        tr = nil
        if row_key_value_callback.present?
          tr = row_key_value_callback.call( depth, key, key_values, row_index ) if row_key_value_callback.present?
        end
        if tr.blank?
          table = key_values_to_table( value,
                                       depth: depth + 1,
                                       on_key_values_to_table_body_callback: on_key_values_to_table_body_callback,
                                       parse: false,
                                       row_key_value_callback: row_key_value_callback,
                                       add_css: add_css,
                                       debug_verbose: debug_verbose )
          table = on_key_values_to_table_body_callback.call( depth, table ) if on_key_values_to_table_body_callback.present?
          css_tr = css_tr( add: add_css, depth: depth )
          css_td = css_td_key( add: add_css, depth: depth )
          css_td2 = css_td( add: add_css, depth: depth )
          tr = "<tr#{css_tr}><td#{css_td}>#{ERB::Util.html_escape( key )}</td><td#{css_td2}>#{table}</td></tr>\n"
        end
        rv += tr
        row_index += 1
      end
      table_body = on_key_values_to_table_body_callback.call( depth, rv ) if on_key_values_to_table_body_callback.present?
      table_body ||= rv
      return "<table#{css_table( add: add_css, depth: depth )}>\n#{table_body}</table>\n"
    elsif key_values.is_a? Numeric
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "Number",
                                             "" ] if debug_verbose
      return key_values.to_s
    elsif [true, false].include? key_values
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "boolean",
                                             "" ] if debug_verbose
      return key_values.to_s
    elsif key_values.nil?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "nil",
                                             "" ] if debug_verbose
      return "&nbsp;"
    else
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "default",
                                             "" ] if debug_verbose
      return ERB::Util.html_escape( key_values.to_s )
    end
  end

  def self.key_values_to_table_safe( key_values,
                                     depth: 0,
                                     on_key_values_to_table_body_callback: nil,
                                     parse:,
                                     row_key_value_callback: nil,
                                     add_css: true,
                                     debug_verbose: json_helper_debug_verbose )
    debug_verbose ||= json_helper_debug_verbose
    key_values_to_table( key_values,
                         depth: depth,
                         on_key_values_to_table_body_callback: on_key_values_to_table_body_callback,
                         parse: parse,
                         row_key_value_callback: row_key_value_callback,
                         add_css: add_css,
                         debug_verbose: debug_verbose )
  rescue Exception => e
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "Exception caught: returning pre",
                                           "e=#{e}",
                                           "" ] + e.backtrace[0..20] if debug_verbose
    return "<pre>#{key_values}</pre>"
  end

  def self.key_values_to_table_string( key_values,
                                       depth:,
                                       on_key_values_to_table_body_callback:,
                                       parse:,
                                       row_key_value_callback:,
                                       add_css: true,
                                       debug_verbose: )

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "key_values.class.name=#{key_values.class.name}",
                                           "key_values=#{key_values}",
                                           "depth=#{depth}",
                                           "parse=#{parse}",
                                           "add_css=#{add_css}",
                                           "" ] if debug_verbose
     return key_values_to_table( JSON.parse( key_values ),
                                 depth: depth,
                                 on_key_values_to_table_body_callback: on_key_values_to_table_body_callback,
                                 parse: false,
                                 row_key_value_callback: row_key_value_callback,
                                 add_css: add_css,
                                 debug_verbose: debug_verbose ) if parse
    return "&nbsp;" if key_values.blank?
    arr = split_str_into_lines( key_values )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "string splits into arr=#{arr}",
                                           "" ] if debug_verbose
    return ERB::Util.html_escape( key_values ) if arr.size <= 1
    arr = arr.map { |x| ERB::Util.html_escape( x ) }
    return "#{arr.join("<br/>")}"
  rescue Exception => e
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "Exception caught: returning pre",
                                           " e=#{e}",
                                           "" ] + e.backtrace[0..20] if debug_verbose
    return "<pre>#{key_values}</pre>"
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
