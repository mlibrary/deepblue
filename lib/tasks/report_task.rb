# frozen_string_literal: true

module Deepblue

  # mattr_accessor :deepblue_report_task_debug_verbose, default: false

  require 'csv'
  # require 'tasks/abstract_report_task'
  require_relative './abstract_report_task'

  class AbstractCurationConcernFilter

    attr_reader :report_task

    def initialize( report_task: )
      super()
      @report_task = report_task
    end

    def filter_in?( curation_concern:, task: )
      false
    end

    def to_string( value )
      value = value.join( " " ) if value.respond_to? :join
      value.to_s unless value.is_a? String
      return value
    end

  end

  class CurationConcernFilterDate < AbstractCurationConcernFilter

    attr_reader :attribute, :begin_date, :end_date

    def to_datetime( date, format, entry: )
      # TODO: see ReportHelper.to_datetime
      return nil if date.blank?
      if format.present?
        begin
          return DateTime.strptime( date, format )
        rescue ArgumentError => e
          report_task.msg_handler.msg_error "Failed to format the date string '#{date}' using format '#{format}' for entry '#{entry}'"
          raise
        end
      end
      case date
      when /^now$/
        return DateTime.now
      when /^now\s+([+-])\s*([0-9]+)\s+(days?|weeks?|months?|years?)$/
        plus_minus = Regexp.last_match 1
        number = Regexp.last_match 2
        number = number.to_i
        units = Regexp.last_match 3
        if '-' == plus_minus
          case units
          when 'day'
            return DateTime.now - number.day
          when 'days'
            return DateTime.now - number.days
          when 'week'
            return DateTime.now - number.week
          when 'weeks'
            return DateTime.now - number.weeks
          when 'month'
            return DateTime.now - number.month
          when 'months'
            return DateTime.now - number.months
          when 'year'
            return DateTime.now - number.year
          when 'years'
            return DateTime.now - number.years
          else
            raise RuntimeError 'Should never get here.'
          end
        else
          case units
          when 'day'
            return DateTime.now + number.day
          when 'days'
            return DateTime.now + number.days
          when 'week'
            return DateTime.now + number.week
          when 'weeks'
            return DateTime.now + number.weeks
          when 'month'
            return DateTime.now + number.month
          when 'months'
            return DateTime.now + number.months
          when 'year'
            return DateTime.now + number.year
          when 'years'
            return DateTime.now + number.years
          else
            raise RuntimeError 'Should never get here.'
          end
        end
      else
        begin
          return DateTime.parse( date )
        rescue ArgumentError => e
          report_task.msg_handler.msg_error "Failed parse relative ('now') date string '#{date}' (ignoring format '#{format}') for entry '#{entry}'"
          raise e
        end
      end
    end

    def initialize( report_task:, attribute:, parms: )
      super( report_task: report_task )
      @attribute = attribute
      @begin_date = to_datetime( parms[:begin], parms[:format], entry: 'begin_date' )
      @end_date = to_datetime( parms[:end], parms[:format], entry: 'end_date' )
      # report_task.msg_handler.msg "@attribute=#{@attribute} @begin_date=#{@begin_date} and @end_date=#{@end_date}" if report_task.verbose
    end

    def include?( curation_concern:, task: )
      # report_task.msg_handler.msg "CurationConcernFilterDate.include? #{curation_concern.id}" if report_task.verbose
      # report_task.msg_handler.msg "@attribute=#{@attribute} @begin_date=#{@begin_date} and @end_date=#{@end_date}" if report_task.verbose
      date =  task.curation_concern_attribute( curation_concern: curation_concern, attribute: @attribute )
      # report_task.msg_handler.msg "date=#{date}" if report_task.verbose
      return false if date.nil?
      return date >= @begin if @end_date.nil?
      return date <= @end if @begin_date.nil?
      rv = date.between?( @begin_date, @end_date )
      # report_task.msg_handler.msg "rv=#{rv} for #{date} between #{@begin_date} and #{@end_date}" if report_task.verbose
      return rv
    end

  end


  class CurationConcernFilterBlank < AbstractCurationConcernFilter

    def initialize( report_task:, attribute:, parms:, include: true )
      super( report_task: report_task )
      @attribute = attribute
      @include = include
    end

    def include?( curation_concern:, task: )
      value = task.curation_concern_attribute( curation_concern: curation_concern, attribute: @attribute )
      rv = value.blank?
      return rv if @include
      return !rv
    end

  end

  class CurationConcernFilterEquals < AbstractCurationConcernFilter

    def initialize( report_task:, attribute:, parms:, include: true )
      super( report_task: report_task )
      @attribute = attribute
      @value = parms[:equals]
      @include = include
    end

    def include?( curation_concern:, task: )
      value = task.curation_concern_attribute( curation_concern: curation_concern, attribute: @attribute )
      value = to_string( value )
      rv = ( value == @value )
      return rv if @include
      return !rv
    end

  end

  class CurationConcernFilterOr < AbstractCurationConcernFilter

    def initialize( report_task:, subfilters: )
      super( report_task: report_task )
      @subfilters = subfilters
    end

    def include?( curation_concern:, task: )
      return true if subfilters.blank?
      @subfilters.each do |subfilter|
        return true if subfilter.include?( curation_concern: curation_concern, task: task )
      end
      return false
    end

  end

  class CurationConcernFilterStringContains < AbstractCurationConcernFilter

    def initialize( report_task:, attribute:, parms: )
      super( report_task: report_task )
      @attribute = attribute
      @value = parms[:contains]
      @ignore_case = false
      @ignore_case = parms[:ignore_case] if parms.has_key? :ignore_case
      @value.downcase! if @ignore_case
    end

    def include?( curation_concern:, task: )
      value = task.curation_concern_attribute( curation_concern: curation_concern, attribute: @attribute )
      value = to_string( value )
      value.downcase! if @ignore_case
      rv = value.include?( @value )
      return rv
    end

  end

  class CurationConcernFilterStringMatches < AbstractCurationConcernFilter

    def initialize( report_task:, attribute:, parms:, include: true )
      super( report_task: report_task )
      @attribute = attribute
      @regex = Regexp.new parms[:matches]
      @include = include
    end

    def include?( curation_concern:, task: )
      value = task.curation_concern_attribute( curation_concern: curation_concern, attribute: @attribute)
      value = to_string( value )
      rv = ( value.match @regex )
      return rv if @include
      return !rv
    end

  end

  class ReportTask < AbstractReportTask

    DEFAULT_REPORT_EXTENSIONS = [ '.yml', '.yaml' ]

    mattr_accessor :report_task_debug_verbose, default: false

    attr_reader :allowed_path_extensions
    attr_reader :allowed_path_prefixes
    attr_reader :current_child, :current_child_index
    attr_reader :curation_concern, :config, :fields, :field_formats, :filters, :output
    attr_reader :filter_exclude, :filter_include
    attr_reader :include_children, :include_children_parent_columns_blank, :include_children_parent_columns
    attr_reader :report_definitions, :report_definitions_file, :report_title
    attr_reader :field_format_strings, :output_file, :output_format
    attr_reader :reporter

    def initialize( report_definitions_file: nil,
                    reporter: nil,
                    allowed_path_extensions: DEFAULT_REPORT_EXTENSIONS,
                    allowed_path_prefixes: nil,
                    msg_handler: nil,
                    options: {} )

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "report_definitions_file=#{report_definitions_file}",
                                             "reporter=#{reporter}",
                                             "allowed_path_extensions=#{allowed_path_extensions}",
                                             "allowed_path_prefixes=#{allowed_path_prefixes}",
                                             "msg_handler=#{msg_handler}",
                                             "options=#{options}",
                                             "" ] if report_task_debug_verbose
      super( msg_handler: msg_handler, options: options )
      if report_definitions_file.present?
        @report_format = report_definitions_file
        @report_definitions_file = report_definitions_file
        @reporter = reporter
        @allowed_path_extensions = allowed_path_extensions
        @allowed_path_prefixes = allowed_path_prefixes
        load_report_definitions
        @report_title = report_hash_value( key: :report_title, default_value: "Unknown report title" )
        @config = report_sub_hash( key: :config )
        verbose = hash_value( hash: config, key: :verbose, default_value: verbose )
        @include_children = hash_value( hash: config, key: :include_children, default_value: false )
        @include_children_parent_columns_blank = hash_value( hash: config,
                                                             key: :include_children_parent_columns_blank,
                                                             default_value: false )
        @include_children_parent_columns = hash_value( hash: config,
                                                       key: :include_children_parent_columns,
                                                       default_value: {} )
        @field_accessors = report_sub_hash( key: :field_accessors )
        @field_accessor_modes = {}
        @curation_concern = report_hash_value( key: :curation_concern )
        @fields = report_sub_hash( key: :fields )
        @field_formats = report_sub_hash( key: :field_formats )
        @field_format_strings = {}
        @filters = report_sub_hash( key: :filters )
        build_filters
        @output = report_sub_hash( key: :output )
        @email = report_hash_value( key: :email, default_value: [] )
      end
    end

    def build_filters
      filter_exclude_hash = hash_value( hash: filters, key: :exclude )
      filter_include_hash = hash_value( hash: filters, key: :include )
      @filter_exclude = []
      @filter_include = []
      build_filters_from_hash( filters: @filter_exclude, hash: filter_exclude_hash )
      build_filters_from_hash( filters: @filter_include, hash: filter_include_hash )
    end

    def build_filters_from_hash( filters:, hash: )
      return if hash.nil?
      hash.each do |attribute,parms|
        case attribute
        when :create_date
          filters << CurationConcernFilterDate.new( report_task: self, attribute: attribute, parms: parms )
        when :modified_date
          filters << CurationConcernFilterDate.new( report_task: self, attribute: attribute, parms: parms )
        when :fields_contain
          attributes = []
          if parms.has_key? :attributes
            attributes = parms[:attributes]
          end
          next if attributes.blank?
          subfilters = []
          attributes.each do |attribute|
            subfilters << CurationConcernFilterStringContains.new( report_task: self, attribute: attribute, parms: parms )
          end
          filters << CurationConcernFilterOr.new( report_task: self, subfilters: subfilters )
        else
          if parms.has_key? :blank
            filters << CurationConcernFilterBlank.new( report_task: self, attribute: attribute, parms: parms )
          end
          if parms.has_key? :contains
            filters << CurationConcernFilterStringContains.new( report_task: self, attribute: attribute, parms: parms )
          end
          if parms.has_key? :equals
            filters << CurationConcernFilterEquals.new( report_task: self, attribute: attribute, parms: parms )
          end
          if parms.has_key? :matches
            filters << CurationConcernFilterStringMatches.new( report_task: self, attribute: attribute, parms: parms )
          end
        end
      end
    end

    def cell_html( str )
      # TODO: escape html?
      return str unless str =~ /https?\:\/\//
      rv = str.gsub( /(https?\:\/\/[^\s]+)/ ) { |match| "<a href=\"#{match}\">#{match}</a>" }
      return rv
    end

    def child_file_set_id( curation_concern:, attribute: )
      return "" unless include_children
      return "" unless current_child.present?
      current_child.id
    end

    def child_file_set_name( curation_concern:, attribute: )
      return "" unless include_children
      return "" unless current_child.present?
      current_child.label
    end

    def csv_rows_to_html_table( rows )
      table = []
      table << "<table>"
      first_row = true
      rows.each do |row|
        if first_row
          row_html( table, row, cell_tag: 'th' )
          first_row = false
        else
          row_html( table, row )
        end
      end
      table << "</table>"
      return table
    end

    def curation_concern_attribute( curation_concern:, attribute: )
      # msg_handler.msg "curation_concern_attribute: curation_concern=#{curation_concern.id} attribute=#{attribute}" if verbose
      # msg_handler.msg "curation_concern_attribute: current_child_index=#{current_child_index} current_child=#{current_child&.id}" if verbose && include_children
      access_mode = @field_accessor_modes[attribute]
      if access_mode.nil?
        field_accessor = @field_accessors[attribute]
        if field_accessor.nil?
          access_mode = :attribute
        elsif field_accessor.respond_to? :has_key?
          if field_accessor.has_key? :method
            access_mode = :method
          elsif field_accessor.has_key? :attribute
            access_mode = :attribute
          elsif field_accessor.has_key? :report_method
            access_mode = :report_method
          else
            access_mode = :attribute
          end
        else
          access_mode = :attribute
        end
        @field_accessor_modes[attribute] = access_mode
      end
      value = case access_mode
              when :attribute
                resolve_attribute( curation_concern: curation_concern, attribute: attribute )
              when :method
                resolve_method( curation_concern: curation_concern, attribute: attribute )
              when :report_method
                resolve_report_method( curation_concern: curation_concern, attribute: attribute )
              else
                resolve_attribute( curation_concern: curation_concern, attribute: attribute )
              end
      # msg_handler.msg "curation_concern_attribute: attribute=#{attribute} access_mode=#{access_mode} value=#{value}" if verbose
      return value
    end

    def curation_concern_format( attribute:, value: )
      # msg_handler.msg "curation_concern_format: attribute=#{attribute} value=#{value}" if verbose
      return value unless field_formats.has_key? attribute
      return "" if value.nil?
      if value.respond_to? :join
        format_str = field_format_strings[ attribute ]
        return value.join( format_str ) unless format_str.nil?
      end
      if is_date? value
        format_str = field_format_strings[ attribute ]
        return date_to_local_timezone( value ).strftime( format_str ) unless format_str.nil?
      end
      # msg_handler.msg "field_formats=#{field_formats}" if verbose
      formats = hash_value( hash: field_formats, key: attribute )
      # msg_handler.msg "formats=#{formats}" if verbose
      if formats.has_key?( :join ) && value.respond_to?( :join )
        format_str = formats[:join]
        field_format_strings[attribute] = format_str
        return value.join( format_str )
      end
      if formats.has_key?( :date ) && value.present?
        format_str = formats[:date]
        field_format_strings[attribute] = format_str
        return date_to_local_timezone( value ).strftime( format_str )
      end
      if is_html_output? && formats.has_key?( :tag ) && value.present?
        tag = formats[:tag]
        field_format_strings[attribute] = tag
        # return "<a href=\"#{value}\">#{value}</a>" if 'a' == tag
        return "<#{tag}>#{value}</#{tag}>"
      end
      if formats.has_key?( :quote ) && value.present?
        quote = formats[:quote]
        field_format_strings[attribute] = quote
        return "#{quote}#{value}#{quote}"
      end
      # msg_handler.msg "curation_concern_format: fell through, return value=#{value}" if verbose
      if value.respond_to?( :join )
        value = value.join( "" )
      end
      return value
    end

    def curation_concerns
      cc_name = curation_concern
      cc = if cc_name.include? '::'
             cc_name.split( '::' ).reduce( Module, :const_get )
           else
             Module.const_get cc_name
           end
      return cc.all
    end

    def date_to_local_timezone( timestamp )
      return timestamp if timestamp.nil?
      timestamp = timestamp.first if timestamp.respond_to? :first
      timestamp = timestamp.to_datetime if timestamp.is_a? Time
      timestamp = DateTime.parse timestamp if timestamp.is_a? String
      timestamp = timestamp.new_offset( DateTime.now.offset )
      return timestamp
    end

    def email_body
      @email_body ||= email_body_init
    end

    def email_body_init
      lines = []
      lines << "Path to report: #{@output_file}"
      lines << "<br/>"
      #lines << "<pre>" unless is_html_output?
      file_lines = email_body_read_file
      file_lines.each { |fline| lines << fline }
      #lines << "<pre>" unless is_html_output?
      lines.join( "\n" )
    end

    def email_body_read_file
      lines = []
      if is_csv_output?
        rows = []
        CSV.foreach( @output_file ) do |row|
          rows << row
        end
        lines = csv_rows_to_html_table( rows )
      else
        File.open( @output_file, "r" ) do |fin|
          until fin.eof?
            begin
              line = fin.readline
              lines << line.chop
            rescue EOFError
              line = nil
            end
          end
        end
      end
      return lines
    end

    def email_report
      return unless @email.present?
      @email.each { |email_target| email_report_to( email: email_target ) }
    end

    def email_report_to( email: )
      return if email.blank?
      to = email
      subject = @report_title
      body = email_body
      content_type = ::Deepblue::EmailHelper::TEXT_HTML
      email_sent = ::Deepblue::EmailHelper.send_email( to: to,
                                                       subject: subject,
                                                       body: body,
                                                       content_type: content_type )
      ::Deepblue::EmailHelper.log( class_name: 'ReportTask',
                                   current_user: nil,
                                   event: 'ReportTask',
                                   event_note: @report_title,
                                   id: '',
                                   to: to,
                                   subject: subject,
                                   body: body,
                                   content_type: content_type,
                                   email_sent: email_sent )
    end

    def filter_out( curation_concern )
      filter_exclude.each do |filter|
        return true if filter.include?( curation_concern: curation_concern, task: self )
      end
      filter_include.each do |filter|
        return true unless filter.include?( curation_concern: curation_concern, task: self )
      end
      return false
    end

    def hash_value( hash:, key:, default_value: nil )
      # msg_handler.msg "hash_value( hash: #{hash['.name']}, key: #{key}, default_value: #{default_value} )" if verbose
      rv = default_value
      if default_value.instance_of? Hash
        rv = hash[key].deep_dup if hash.key? key
        # msg_handler.msg "report_hash_value rv=#{rv}" if verbose
      else
        rv = hash[key] if hash.key? key
      end
      # msg_handler.msg "report_hash_value rv=#{rv}" if verbose
      return rv
    end

    def is_csv_output?
      'CSV' == @output_format
    end

    def is_date?( value )
      return true if value.is_a? Date
      return true if value.is_a? DateTime
      return false
    end

    def is_html_output?
      'html' == @output_format
    end

    def load_report_definitions
      # msg_handler.msg "report_definitions_file=#{report_definitions_file}" if verbose
      if report_definitions_file_validate
        @report_definitions = YAML.load_file( report_definitions_file )
      else
        raise "report definitions file not found: '#{report_definitions_file}'"
      end
    end

    def report_definitions_file_validate
      file = report_definitions_file
      return false unless file.present?
      return false unless File.exist? file
      ext = File.extname file
      return false unless allowed_path_extensions.include? ext
      if allowed_path_prefixes.present?
        allowed = false
        allowed_path_prefixes.each do |prefix|
          if file.start_with? prefix
            allowed = true
            break
          end
        end
        return false unless allowed
      end
      return true
    end

    def report_hash_value( base_key: :report, key:, default_value: nil )
      # msg_handler.msg "report_hash_value( base_key: #{base_key}, key: #{key}, default_value: #{default_value} )"
      rv = default_value
      if @report_definitions.key? base_key
        rv = @report_definitions[base_key][key] if @report_definitions[base_key].key? key
      end
      # msg_handler.msg "report_hash_value rv=#{rv}"
      return rv
    end

    def report_sub_hash( base_key: :report, key:, default_value: {}, hash_name: nil )
      hash = report_hash_value( base_key: base_key, key: key, default_value: default_value )
      hash_name = key.to_s if hash_name.nil?
      hash['.name'] = hash_name
      return hash
    end

    def resolve_attribute( curation_concern:, attribute: )
      # msg_handler.msg "resolve_attribute: curation_concern.id=#{curation_concern.id} attribute: #{attribute}"
      if include_children && current_child_index > 1
        # msg_handler.msg "include_children_parent_columns_blank=#{include_children_parent_columns_blank}"
        # msg_handler.msg "include_children_parent_columns=#{include_children_parent_columns} attribute=#{attribute} !include_children_parent_columns[attribute]=#{!include_children_parent_columns[attribute]}"
        if include_children_parent_columns_blank && !include_children_parent_columns[attribute]
          rv = ""
          # msg_handler.msg "resolve_attribute: blankd child column rv=#{rv}"
          return rv
        end
      end
      rv = curation_concern.attributes[attribute.to_s]
      # msg_handler.msg "resolve_attribute: rv=#{rv}"
      return rv
    end

    def resolve_method( curation_concern:, attribute: )
      if include_children && current_child_index > 1
        return "" if include_children_parent_columns_blank && !include_children_parent_columns[attribute.to_s]
      end
      raise unless curation_concern.respond_to? attribute.to_s
      curation_concern.public_send( attribute.to_s )
    end

    def resolve_report_method( curation_concern:, attribute: )
      raise unless respond_to? attribute.to_s
      public_send( attribute.to_s, { curation_concern: curation_concern, attribute: attribute } )
    end

    def row_html( table, row, cell_tag: 'td' )
      table << "<tr>"
      row_out = []
      row.each do |cell|
        row_out << "<#{cell_tag}>#{cell_html(cell)}</#{cell_tag}>"
      end
      table << row_out.join('')
      table << "</tr>"
    end

    def row_html_puts( out, row, cell_tag: 'td' )
      out.puts "<tr>"
      row.each do |cell|
        out.write "<#{cell_tag}>#{cell_html(cell)}</#{cell_tag}>"
      end
      out.puts
      out.puts "</tr>"
    end

    def row_csv_header
      header = []
      fields.each do |attribute,value|
        next if attribute.to_s.start_with? '.'
        header << value
      end
      return header
    end

    def row_csv_data( curation_concern )
      row = []
      fields.each do |attribute,_value|
        next if attribute.to_s.start_with? '.'
        value = curation_concern_attribute( curation_concern: curation_concern, attribute: attribute )
        value = curation_concern_format( attribute: attribute, value: value )
        row << value
      end
      return row
    end

    def update_output_file_name
      @output_file = expand_path_partials( @output_file )
      now = DateTime.now
      # legacy replacements
      update_output_file_name_date_int( /%Y(YYY)?/, now.year )
      update_output_file_name_date_int( /%mm?/, now.month )
      update_output_file_name_date_int( /%dd?/, now.day )
      update_output_file_name_date_int( /%HH?/, now.hour )
      update_output_file_name_date_int( /%MM?/, now.minute )
      update_output_file_name_date_int( /%SS?/, now.second )
    end

    def update_output_file_name_date_int( regexp, date_int )
      return unless @output_file =~ regexp
      replacement = date_int.to_s
      replacement = "0#{replacement}" if replacement.size < 2
      @output_file.gsub!( regexp, replacement )
    end

    def update_output_file_name_regexp( regexp, replacement )
      return unless @output_file =~ regexp
      @output_file.gsub!( regexp, replacement )
    end

    def write_report
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "verbose=#{verbose}",
                                             "" ] if report_task_debug_verbose
      msg_handler.msg "curation_concern=#{curation_concern}" if verbose
      @output_file = hash_value( hash: output, key: :file )
      update_output_file_name
      msg_handler.msg "output_file=#{output_file}" if verbose
      @output_format = hash_value( hash: output, key: :format )
      msg_handler.msg "output_format=#{@output_format}" if verbose
      fields.each do |name,value|
        next if name.to_s.start_with? '.'
        msg_handler.msg "field: #{name}=#{value}" if verbose
      end
      case @output_format
      when 'CSV'
        write_report_csv
      when 'html'
        write_report_html
      end
      msg_handler.msg "report written to #{output_file}"
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if report_task_debug_verbose
    end

    def write_report_csv
      @output_file = output_file + ".csv"
      CSV.open( output_file, "w", {:force_quotes=>true} ) do |csv|
        csv << row_csv_header
        curation_concerns.each do |curation_concern|
          @current_child = nil
          @current_child_index = 0
          next if filter_out( curation_concern )
          if include_children
            file_sets = curation_concern.file_sets
            if file_sets.present?
              file_sets.each_with_index do |fs,index|
                @current_child = fs
                @current_child_index = index + 1
                csv << row_csv_data( curation_concern )
              end
            else
              csv << row_csv_data( curation_concern )
            end
          else
            csv << row_csv_data( curation_concern )
          end
        end
      end
    end

    def write_report_html
      @output_file = output_file + ".html"
      File.open( output_file, "w" ) do |out|
        out.puts "<table>"
        row_html_puts( out, row_csv_header, cell_tag: 'th' )
        curation_concerns.each do |curation_concern|
          @current_child = nil
          @current_child_index = 0
          next if filter_out( curation_concern )
          if include_children
            file_sets = curation_concern.file_sets
            if file_sets.present?
              file_sets.each_with_index do |fs,index|
                @current_child = fs
                @current_child_index = index + 1
                row_html_puts( out, row_csv_data( curation_concern ) )
              end
            else
              row_html_puts( out, row_csv_data( curation_concern ) )
            end
          else
            row_html_puts( out, row_csv_data( curation_concern ) )
          end
        end
        out.puts "</table>"
      end
    end

  end

end
