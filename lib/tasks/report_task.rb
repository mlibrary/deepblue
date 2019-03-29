# frozen_string_literal: true

module Deepblue

  require 'csv'
  require 'tasks/abstract_report_task'

  class AbstractCurationConcernFilter

    def curation_concern_attribute( curation_concern, attribute )
      value = case attribute
              when :create_date
                curation_concern.create_date
              when :modified_date
                curation_concern.modified_date
              else
                curation_concern.attributes[attribute.to_s]
              end
      return value
    end

    def include( curation_concern )
      false
    end

    def to_string( value )
      value = value.join( " " ) if value.respond_to? :join
      value.to_s unless value.is_a? String
      return value
    end

  end

  class CurationConcernFilterDate < AbstractCurationConcernFilter

    def to_datetime( date, format )
      return nil if date.blank?
      return DateTime.parse( date ) if format.nil?
      return DateTime.strptime( date, format )
    end

    def initialize( attribute:, parms: )
      @attribute = attribute
      @begin_date = to_datetime( parms[:begin], parms[:format] )
      @end_date = to_datetime( parms[:end], parms[:format] )
    end

    def include( curation_concern )
      date =  curation_concern_attribute( curation_concern, @attribute )
      return date >= @begin if @end_date.nil?
      return date <= @end if @begin_date.nil?
      rv = date.between?( @begin_date, @end_date )
      return rv
    end

  end

  class CurationConcernFilterBlank < AbstractCurationConcernFilter

    def initialize( attribute:, parms:, include: true )
      @attribute = attribute
      @include = include
    end

    def include( curation_concern )
      value = curation_concern_attribute( curation_concern, @attribute )
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

    def include( curation_concern )
      value = curation_concern_attribute( curation_concern, @attribute )
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

    def include( curation_concern )
      value = curation_concern_attribute( curation_concern, @attribute )
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

    def include( curation_concern )
      value = curation_concern_attribute( curation_concern, @attribute )
      value = to_string( value )
      rv = ( value.match @regex )
      return rv if @include
      return !rv
    end

  end

  class ReportTask < AbstractReportTask

    attr_reader :curation_concern, :config, :fields, :field_formats, :filters, :output
    attr_reader :filter_exclude, :filter_include
    attr_reader :report_definitions, :report_definitions_file
    attr_reader :field_format_strings, :output_file

    def initialize( report_definitions_file:, options: {} )
      super( options: options )
      @report_format = report_definitions_file
      @report_definitions_file = report_definitions_file
      load_report_definitions
      @config = report_sub_hash( key: :config )
      @verbose = hash_value( hash: config, key: :verbose, default_value: verbose )
      @curation_concern = report_hash_value( key: :curation_concern )
      @fields = report_sub_hash( key: :fields )
      @field_formats = report_sub_hash( key: :field_formats )
      @field_format_strings = {}
      @filters = report_sub_hash( key: :filters )
      build_filters
      @output = report_sub_hash( key: :output )
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

    def curation_concern_attribute( curation_concern, attribute )
      value = case attribute
              when :create_date
                curation_concern.create_date
              when :modified_date
                curation_concern.modified_date
              else
                curation_concern.attributes[attribute.to_s]
              end
      value = curation_concern_format( attribute, value )
      return value
    end

    def curation_concern_format( attribute, value )
      return value unless field_formats.has_key? attribute
      if value.respond_to? :join
        format_str = field_format_strings[ attribute ]
        return value.join( format_str ) unless format_str.nil?
      end
      if is_date? value
        format_str = field_format_strings[ attribute ]
        return date_to_local_timezone( value ).strftime( format_str ) unless format_str.nil?
      end
      # puts "field_formats=#{field_formats}"
      formats = hash_value( hash: field_formats, key: attribute )
      # puts "formats=#{formats}"
      if formats.has_key? :join
        format_str = formats[:join]
        field_format_strings[attribute] = format_str
        return value.join( format_str )
      end
      if formats.has_key? :date
        format_str = formats[:date]
        field_format_strings[attribute] = format_str
        return date_to_local_timezone( value ).strftime( format_str )
      end
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
      timestamp = timestamp.to_datetime if timestamp.is_a? Time
      timestamp = DateTime.parse timestamp if timestamp.is_a? String
      timestamp = timestamp.new_offset( DateTime.now.offset )
      return timestamp
    end

    def filter_out( curation_concern )
      filter_exclude.each do |filter|
        return true if filter.include( curation_concern )
      end
      filter_include.each do |filter|
        return true unless filter.include( curation_concern )
      end
      return false
    end

    def hash_value( hash:, key:, default_value: nil )
      # puts "hash_value( hash: #{hash['.name']}, key: #{key}, default_value: #{default_value} )"
      rv = default_value
      rv = hash[key] if hash.key? key
      # puts "report_hash_value rv=#{rv}"
      return rv
    end

    def is_date?( value )
      return true if value.is_a? Date
      return true if value.is_a? DateTime
      return false
    end

    def load_report_definitions
      puts "report_definitions_file=#{report_definitions_file}"
      if File.exist? report_definitions_file
        @report_definitions = YAML.load_file( report_definitions_file )
      else
        raise "report definitions file not found: '#{report_definitions_file}'"
      end
    end

    def report_hash_value( base_key: :report, key:, default_value: nil )
      # puts "report_hash_value( base_key: #{base_key}, key: #{key}, default_value: #{default_value} )"
      rv = default_value
      if @report_definitions.key? base_key
        rv = @report_definitions[base_key][key] if @report_definitions[base_key].key? key
      end
      # puts "report_hash_value rv=#{rv}"
      return rv
    end

    def report_sub_hash( base_key: :report, key:, default_value: {}, hash_name: nil )
      hash = report_hash_value( base_key: base_key, key: key, default_value: default_value )
      hash_name = key.to_s if hash_name.nil?
      hash['.name'] = hash_name
      return hash
    end

    def write_report
      puts "curation_concern=#{curation_concern}"
      @output_file = hash_value( hash: output, key: :file )
      puts "output_file=#{output_file}"
      output_format = hash_value( hash: output, key: :format )
      puts "output_format=#{output_format}"
      fields.each do |name,value|
        next if name.to_s.start_with? '.'
        puts "field: #{name}=#{value}"
      end
      case output_format
      when "CSV"
        write_report_csv
      end
      puts "report written to #{output_file}"
    end

    def write_report_csv
      @output_file = output_file + ".csv"
      CSV.open( output_file, "w" ) do |csv|
        csv << row_csv_header
        curation_concerns.each do |curation_concern|
          next if filter_out( curation_concern )
          csv << row_csv_data( curation_concern )
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
        row << curation_concern_attribute( curation_concern, attribute )
      end
      return row
    end

  end

end
