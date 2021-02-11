# frozen_string_literal: true

module Deepblue

  # mattr_accessor :deepblue_report_task_debug_verbose
  # @@deepblue_report_task_debug_verbose = true

  require 'csv'
  # require 'tasks/abstract_report_task'
  require_relative './abstract_report_task'

  class AbstractCurationConcernFilter

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
      return nil if date.blank?
      if format.nil?
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
          return DateTime.parse( date ) if format.nil?
        end
      end
      rv = nil
      begin
        rv = DateTime.strptime( date, format )
      rescue ArgumentError => e
        msg_puts "ERROR: ArgumentError in CurationConcernFilterDate.to_datetime( #{date}, #{format}, entry: #{entry} )"
        raise e
      end
      return rv
    end

    def initialize( attribute:, parms: )
      @attribute = attribute
      @begin_date = to_datetime( parms[:begin], parms[:format], entry: 'begin_date' )
      @end_date = to_datetime( parms[:end], parms[:format], entry: 'end_date' )
      # msg_puts "@attribute=#{@attribute} @begin_date=#{@begin_date} and @end_date=#{@end_date}" if verbose
    end

    def include?( curation_concern:, task: )
      # msg_puts "CurationConcernFilterDate.include? #{curation_concern.id}" if verbose
      # msg_puts "@attribute=#{@attribute} @begin_date=#{@begin_date} and @end_date=#{@end_date}" if verbose
      date =  task.curation_concern_attribute( curation_concern: curation_concern, attribute: @attribute )
      # msg_puts "date=#{date}" if verbose
      return false if date.nil?
      return date >= @begin if @end_date.nil?
      return date <= @end if @begin_date.nil?
      rv = date.between?( @begin_date, @end_date )
      # msg_puts "rv=#{rv} for #{date} between #{@begin_date} and #{@end_date}" if verbose
      return rv
    end

  end


  class CurationConcernFilterBlank < AbstractCurationConcernFilter

    def initialize( attribute:, parms:, include: true )
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

    def initialize( attribute:, parms:, include: true )
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

  class CurationConcernFilterStringContains < AbstractCurationConcernFilter

    def initialize( attribute:, parms: )
      @attribute = attribute
      @value = parms[:contains]
      @ignore_case = false
      @ignore_case = parms[:igmore_case] if parms.has_key? :ignore_case
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

    def initialize( attribute:, parms:, include: true )
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

    mattr_accessor :report_task_verbose_debug
    @@report_task_verbose_debug = false

    attr_reader :allowed_path_extensions
    attr_reader :allowed_path_prefixes
    attr_reader :current_child, :current_child_index
    attr_reader :curation_concern, :config, :fields, :field_formats, :filters, :output
    attr_reader :filter_exclude, :filter_include
    attr_reader :include_children, :include_children_parent_columns_blank, :include_children_parent_columns
    attr_reader :report_definitions, :report_definitions_file
    attr_reader :field_format_strings, :output_file
    attr_reader :reporter
    attr_reader :msg_queue

    def initialize( report_definitions_file: nil,
                    reporter: nil,
                    allowed_path_extensions: DEFAULT_REPORT_EXTENSIONS,
                    allowed_path_prefixes: nil,
                    msg_queue: nil,
                    verbose: false,
                    options: {} )

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "report_definitions_file=#{report_definitions_file}",
                                             "reporter=#{reporter}",
                                             "allowed_path_extensions=#{allowed_path_extensions}",
                                             "allowed_path_prefixes=#{allowed_path_prefixes}",
                                             "msg_queue=#{msg_queue}",
                                             "verbose=#{verbose}",
                                             "options=#{options}",
                                             "" ] if report_task_verbose_debug
      super( options: options )
      self.verbose = verbose
      @verbose = verbose
      @msg_queue = msg_queue
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "verbose=#{verbose}",
                                             "msg_queue=#{msg_queue}",
                                             "" ] if report_task_verbose_debug
      if report_definitions_file.present?
        @report_format = report_definitions_file
        @report_definitions_file = report_definitions_file
        @reporter = reporter
        @allowed_path_extensions = allowed_path_extensions
        @allowed_path_prefixes = allowed_path_prefixes
        load_report_definitions
        @config = report_sub_hash( key: :config )
        @verbose = hash_value( hash: config, key: :verbose, default_value: verbose )
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
          filters << CurationConcernFilterDate.new( attribute: attribute, parms: parms )
        when :modified_date
          filters << CurationConcernFilterDate.new( attribute: attribute, parms: parms )
        else
          if parms.has_key? :blank
            filters << CurationConcernFilterBlank.new( attribute: attribute, parms: parms )
          end
          if parms.has_key? :contains
            filters << CurationConcernFilterStringContains.new( attribute: attribute, parms: parms )
          end
          if parms.has_key? :equals
            filters << CurationConcernFilterEquals.new( attribute: attribute, parms: parms )
          end
          if parms.has_key? :matches
            filters << CurationConcernFilterStringMatches.new( attribute: attribute, parms: parms )
          end
        end
      end
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

    def curation_concern_attribute( curation_concern:, attribute: )
      # msg_puts "curation_concern_attribute: curation_concern=#{curation_concern.id} attribute=#{attribute}" if verbose
      # msg_puts "curation_concern_attribute: current_child_index=#{current_child_index} current_child=#{current_child&.id}" if verbose && include_children
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
      # msg_puts "curation_concern_attribute: attribute=#{attribute} access_mode=#{access_mode} value=#{value}" if verbose
      return value
    end

    def curation_concern_format( attribute:, value: )
      # msg_puts "curation_concern_format: attribute=#{attribute} value=#{value}" if verbose
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
      # msg_puts "field_formats=#{field_formats}" if verbose
      formats = hash_value( hash: field_formats, key: attribute )
      # msg_puts "formats=#{formats}" if verbose
      if formats.has_key? :join && value.respond_to?( :join )
        format_str = formats[:join]
        field_format_strings[attribute] = format_str
        return value.join( format_str )
      end
      if formats.has_key? :date && value.present?
        format_str = formats[:date]
        field_format_strings[attribute] = format_str
        return date_to_local_timezone( value ).strftime( format_str )
      end
      # msg_puts "curation_concern_format: fell through, return value=#{value}" if verbose
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
      timestamp = timestamp.to_datetime if timestamp.is_a? Time
      timestamp = DateTime.parse timestamp if timestamp.is_a? String
      timestamp = timestamp.new_offset( DateTime.now.offset )
      return timestamp
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
      # msg_puts "hash_value( hash: #{hash['.name']}, key: #{key}, default_value: #{default_value} )" if verbose
      rv = default_value
      if default_value.instance_of? Hash
        rv = hash[key].deep_dup if hash.key? key
        # msg_puts "report_hash_value rv=#{rv}" if verbose
      else
        rv = hash[key] if hash.key? key
      end
      # msg_puts "report_hash_value rv=#{rv}" if verbose
      return rv
    end

    def is_date?( value )
      return true if value.is_a? Date
      return true if value.is_a? DateTime
      return false
    end

    def load_report_definitions
      # msg_puts "report_definitions_file=#{report_definitions_file}" if verbose
      if report_definitions_file_validate
        @report_definitions = YAML.load_file( report_definitions_file )
      else
        raise "report definitions file not found: '#{report_definitions_file}'"
      end
    end

    def msg_puts( msg )
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "verbose=#{verbose}",
      #                                        "msg=#{msg}",
      #                                        "msg_queue=#{msg_queue}",
      #                                        "" ] if report_task_verbose_debug
      mq = msg_queue
      if mq.is_a? Array
        mq << msg
        # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
        #                                        ::Deepblue::LoggingHelper.called_from,
        #                                        "msg=#{msg}",
        #                                        "msg_queue=#{msg_queue}",
        #                                        "" ] if report_task_verbose_debug
        return
      end
      puts msg
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
      # msg_puts "report_hash_value( base_key: #{base_key}, key: #{key}, default_value: #{default_value} )"
      rv = default_value
      if @report_definitions.key? base_key
        rv = @report_definitions[base_key][key] if @report_definitions[base_key].key? key
      end
      # msg_puts "report_hash_value rv=#{rv}"
      return rv
    end

    def report_sub_hash( base_key: :report, key:, default_value: {}, hash_name: nil )
      hash = report_hash_value( base_key: base_key, key: key, default_value: default_value )
      hash_name = key.to_s if hash_name.nil?
      hash['.name'] = hash_name
      return hash
    end

    def resolve_attribute( curation_concern:, attribute: )
      # msg_puts "resolve_attribute: curation_concern.id=#{curation_concern.id} attribute: #{attribute}"
      if include_children && current_child_index > 1
        # msg_puts "include_children_parent_columns_blank=#{include_children_parent_columns_blank}"
        # msg_puts "include_children_parent_columns=#{include_children_parent_columns} attribute=#{attribute} !include_children_parent_columns[attribute]=#{!include_children_parent_columns[attribute]}"
        if include_children_parent_columns_blank && !include_children_parent_columns[attribute]
          rv = ""
          # msg_puts "resolve_attribute: blankd child column rv=#{rv}"
          return rv
        end
      end
      rv = curation_concern.attributes[attribute.to_s]
      # msg_puts "resolve_attribute: rv=#{rv}"
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

    def update_output_file_name( regexp, date_int )
      return unless @output_file =~ regexp
      replacement = date_int.to_s
      replacement = "0#{replacement}" if replacement.size < 2
      @output_file.gsub!( regexp, replacement )
    end

    def write_report
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "verbose=#{verbose}",
                                             "msg_queue=#{msg_queue}",
                                             "" ] if report_task_verbose_debug
      msg_puts "curation_concern=#{curation_concern}" if verbose
      @output_file = hash_value( hash: output, key: :file )
      now = DateTime.now
      update_output_file_name( /%Y(YYY)?/, now.year )
      update_output_file_name( /%mm?/, now.month )
      update_output_file_name( /%dd?/, now.day )
      update_output_file_name( /%HH?/, now.hour )
      update_output_file_name( /%MM?/, now.minute )
      update_output_file_name( /%SS?/, now.second )
      msg_puts "output_file=#{output_file}" if verbose
      output_format = hash_value( hash: output, key: :format )
      msg_puts "output_format=#{output_format}" if verbose
      fields.each do |name,value|
        next if name.to_s.start_with? '.'
        msg_puts "field: #{name}=#{value}" if verbose
      end
      case output_format
      when "CSV"
        write_report_csv
      end
      msg_puts "report written to #{output_file}"
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "msg_queue=#{msg_queue}",
                                             "" ] if report_task_verbose_debug
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

  end

end
