# frozen_string_literal: true

# rubocop:disable Metrics/ParameterLists
module Deepblue

  class AbstractFilter

    mattr_accessor :abstract_filter_debug_verbose,
                   default: Rails.configuration.abstract_filter_debug_verbose

    attr_accessor :verbose

    def initialize( options: {} )
      @verbose = options_value( options, key: "verbose_filters", default_value: false )
      # @verbose = options_value( options, key: "verbose_filters", default_value: true )
      return unless @verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "verbose=#{verbose}",
                                             "" ] if abstract_filter_debug_verbose
      puts "#{::Deepblue::LoggingHelper.here} self.class.name=#{self.class.name}"
      puts "#{::Deepblue::LoggingHelper.here} options=#{options}"
      puts "#{::Deepblue::LoggingHelper.here} verbose=#{verbose}"
    end

    protected

      def options_value( options, key:, default_value: nil, verbose: false )
        return default_value if options.blank?
        return default_value unless options.key? key
        puts "set key #{key} to #{options[key]}" if verbose
        return options[key]
      end

  end

  class AbstractArrayOfFilters < AbstractFilter

    attr_reader :filters

    def initialize( filters: [], options: {} )
      super( options: options )
      @filters = Array( filters )
    end

    def add_filters( new_filters:, append: true )
      new_filters = Array( new_filters )
      if append
        @filters.concat new_filters
      else
        until new_filters.empty?
          filter = new_filters.pop
          @filters.unshift filter
        end
      end
      return self
    end

    def all_log_filter?
      false
    end

  end

  class AndLogFilter < AbstractArrayOfFilters

    def initialize( filters: [], options: {} )
      super( filters: filters, options: options )
    end

    def and( new_filters: )
      add_filters( new_filters: new_filters )
    end

    def or( new_filters: )
      new_filter = OrLogFilter.new( filters: self ).add_filters( new_filters: new_filters )
      return new_filter
    end

    def filter_in( reader, timestamp, event, event_note, class_name, id, raw_key_values )
      filters.each do |filter|
        return false unless filter.filter_in( reader, timestamp, event, event_note, class_name, id, raw_key_values )
      end
      return true
    end

  end

  class OrLogFilter < AbstractArrayOfFilters

    def initialize( filters: [], options: {} )
      super( filters: filters, options: options )
    end

    def and( new_filters: )
      new_filter = AndLogFilter.new( filters: self ).add_filters( new_filters: new_filters )
      return new_filter
    end

    def or( new_filters: )
      add_filters( new_filters: new_filters )
    end

    def filter_in( reader, timestamp, event, event_note, class_name, id, raw_key_values )
      filters.each do |filter|
        return true if filter.filter_in( reader, timestamp, event, event_note, class_name, id, raw_key_values )
      end
      return false
    end

  end

  class AbstractLogFilter < AbstractFilter

    def initializer( options: {} )
      super( options: options )
    end

    def all_log_filter?
      false
    end

    def and( new_filters: )
      new_filter = AndLogFilter.new( filters: self ).add_filters( new_filters: new_filters )
      return new_filter
    end

    def or( new_filters: )
      new_filter = OrLogFilter.new( filters: self ).add_filters( new_filters: new_filters )
      return new_filter
    end

    def filter_in( _reader, _timestamp, _event, _event_note, _class_name, _id, _raw_key_values )
      puts "#{::Deepblue::LoggingHelper.here} filter_in returning false"
      false
    end

    protected

      def arg_to_array( arg )
        arr = if arg.is_a? String
                arg.split( ' ' )
              else
                Array( arg )
              end
        return arr
      end

      def arg_to_timestamp( arg, timestamp_format: )
        timestamp = arg
        return timestamp if timestamp.is_a? DateTime
        return timestamp.to_datetime if timestamp.is_a? Date
        if timestamp_format.blank? && arg.is_a?( String )
          return DateTime.strptime( arg, "%Y-%m-%d %H:%M:%S" ) if arg.match?( /\d\d\d\d\-\d\d?\-\d\d? \d\d?:\d\d:\d\d/ )
          return DateTime.strptime( arg, "%m/%d/%Y" ) if arg.match?( /\d\d?\/\d\d?\/\d\d\d\d/ )
          return DateTime.strptime( arg, "%m-%d-%Y" ) if arg.match?( /\d\d?\-\d\d?\-\d\d\d\d/ )
          return DateTime.strptime( arg, "%Y" ) if arg.match?( /\d\d\d\d/ )
          timestamp = DateTime.parse( arg ) if arg.present? && arg.is_a?( String )
        elsif arg.is_a? String
          timestamp = DateTime.strptime( arg, timestamp_format )
        end
        return timestamp
      rescue ArgumentError
        puts "DateTime.parse failed - arg='#{arg}' timestamp_format='#{timestamp_format}'" # - #{e.class}: #{e.message} at #{e.backtrace[0]}"
      end

      def parse_key_values( raw_key_values )
        ProvenanceHelper.parse_log_line_key_values raw_key_values
      end

  end

  class NotLogFilter < AbstractLogFilter

    attr_reader :filter

    def initialize( filter:, options: {} )
      super( options: options )
      @filter = filter
    end

    def filter_in( reader, timestamp, event, event_note, class_name, id, raw_key_values )
      rv = @filter.filter_in( reader, timestamp, event, event_note, class_name, id, raw_key_values )
      return !rv
    end

  end

  class AllLogFilter < AbstractLogFilter

    def initialize( options: {} )
      super( options: options )
    end

    def all_log_filter?
      true
    end

    def filter_in( _reader, _timestamp, _event, _event_note, _class_name, _id, _raw_key_values )
      true
    end

  end

  class ClassNameLogFilter < AbstractLogFilter

    attr_reader :matching_class_names

    def initialize( matching_class_names: [], options: {} )
      super( options: options )
      @matching_classe_names = arg_to_array matching_class_names
    end

    def filter_in( _reader, _timestamp, _event, _event_note, class_name, _id, _raw_key_values )
      puts "#{@matching_classe_names} include? #{class_name}" if verbose
      @matching_classe_names.include? class_name
    end

  end

  class CollectionLogFilter < ClassNameLogFilter

    def initialize( options: {} )
      super( matching_class_names: [ Collection.name ], options: options )
    end

  end

  class DataSetLogFilter < ClassNameLogFilter

    def initialize( options: {} )
      super( matching_class_names: [ DataSet.name ], options: options )
    end

  end

  class DateLogFilter < AbstractLogFilter

    attr_reader :begin_timestamp, :end_timestamp

    # Examples:
    #
    # filter = Deepblue::DataLogFilter.new( begin_timestamp: Date.new=( 2018, 08, 17 ) )
    # filter = Deepblue::DataLogFilter.new( begin_timestamp: DateTime.new( 2018, 08, 17, 10, 0, 0 ) )
    # filter = Deepblue::DataLogFilter.new( begin_timestamp: DateTime.now - 3.days )
    #
    # filter = Deepblue::DataLogFilter.new( begin_timestamp: '2018/08/17', timestamp_format: '%Y/%m/%d' )
    # filter = Deepblue::DataLogFilter.new( begin_timestamp: '2018/08/17 12:10:00', timestamp_format: '%Y/%m/%d %H:%M:%S' )
    #
    # filter = Deepblue::DateLogFilter.new( begin_timestamp: "2018-08-16 15:00:00", timestamp_format: '%Y-%m-%d %H:%M:%S' )
    #
    # filter = Deepblue::DateLogFilter.new( begin_timestamp: Date.new - 2.days )
    #
    def initialize( begin_timestamp: nil, end_timestamp: nil, timestamp_format: '', options: {} )
      super( options: options )
      @begin_timestamp = arg_to_timestamp( begin_timestamp, timestamp_format: timestamp_format )
      @end_timestamp = arg_to_timestamp( end_timestamp, timestamp_format: timestamp_format )
    end

    def filter_in( _reader, timestamp, _event, _event_note, _class_name, _id, _raw_key_values )
      before_begin = false
      before_begin = timestamp < @begin_timestamp if @begin_timestamp.present?
      after_end = false
      after_end = timestamp > @end_timestamp if @end_timestamp.present?
      rv = !before_begin && !after_end
      if verbose
        puts "@begin_timestamp=#{@begin_timestamp} and @after_timestamp=#{@end_timestamp}"
        puts "#{::Deepblue::LoggingHelper.here} filter_in returning..."
        puts "#{timestamp} is before_begin? #{before_begin} and #{timestamp} is after_end? #{after_end}"
        puts "filter_in rv=#{rv}"
      end
      rv
    end

    def begin_timestamp_label
      ts = begin_timestamp
      return '' if ts.blank?
      ts.strftime "%Y%m%d%H%M%S"
    end

    def end_timestamp_label
      ts = end_timestamp
      return '' if ts.blank?
      ts.strftime "%Y%m%d%H%M%S"
    end

    def date_range_label
      ts1 = begin_timestamp_label
      ts2 = end_timestamp_label
      return '' if ts1.blank? && ts2.blank?
      return ts1 if ts2.blank?
      return ts2 if ts1.blank?
      return "#{ts1}-#{ts2}"
    end

  end

  class EventLogFilter < AbstractLogFilter

    attr_reader :matching_events

    def initialize( matching_events: [], options: {} )
      super( options: options )
      @matching_events = arg_to_array matching_events
    end

    def filter_in( _reader, _timestamp, event, _event_note, _class_name, _id, _raw_key_values )
      puts "#{@matching_events} include? #{event}" if verbose
      @matching_events.include? event
    end

  end

  class CreateOrDestroyLogFilter < EventLogFilter

    def initialize( options: {} )
      super( matching_events: [ AbstractEventBehavior::EVENT_CREATE, AbstractEventBehavior::EVENT_DESTROY ],
             options: options )
    end

  end

  class FileSetFilter < ClassNameLogFilter

    def initialize( options: {} )
      super( matching_class_names: [ FileSet.name ], options: options )
    end

  end

  class FixityCheckLogFilter < EventLogFilter

    def initialize( options: {} )
      super( matching_events: [ AbstractEventBehavior::EVENT_FIXITY_CHECK ], options: options )
    end

  end

  class LinesFilter < AbstractLogFilter

    attr_reader :begin_line_num, :end_line_num

    def initialize( begin_line: nil, end_line: nil, options: {} )
      super( options: options )
      @begin_line_num = begin_line.to_i
      @end_line_num = end_line.to_i
    end

    def filter_in( reader, _timestamp, _event, _event_note, _class_name, _id, _raw_key_values )
      current_line_num = reader.lines_read
      before_begin = false
      before_begin = current_line_num < @begin_line_num if @begin_line_num.present?
      after_end = false
      after_end = current_line_num > @end_line_num if @end_line_num.present?
      puts "@begin_line_num=#{@begin_line_num} and @end_line_num=#{@end_line_num}"
      puts "#{::Deepblue::LoggingHelper.here} filter_in returning..."
      puts "#{current_line_num} is before_begin? #{before_begin} and #{current_line_num} is after_end? #{after_end}"
      return !before_begin && !after_end
    end

    def begin_line_num_label
      num = begin_line_num
      return '' if num.blank?
      num.to_s
    end

    def end_line_num_label
      num = end_line_num
      return '' if num.blank?
      num.to_s
    end

    def date_range_label
      num1 = begin_line_num_label
      num2 = end_line_num_label
      return '' if num1.blank? && num2.blank?
      return num1 if num2.blank?
      return num2 if num1.blank?
      return "#{num1}-#{num2}"
    end

  end

  class MigrationEventFilter < EventLogFilter

    def initialize( options: {} )
      super( matching_events: [ AbstractEventBehavior::EVENT_CHILD_ADD,
                                AbstractEventBehavior::EVENT_FIXITY_CHECK,
                                AbstractEventBehavior::EVENT_INGEST,
                                AbstractEventBehavior::EVENT_MIGRATE,
                                AbstractEventBehavior::EVENT_VIRUS_SCAN ],
             options: options )
    end

  end

  class UserEmailLogFilter < AbstractLogFilter

    mattr_accessor :email_log_filter_debug_verbose, default: false

    attr_reader :user_email

    def initialize( user_email:, options: {} )
      super( options: options )
      @user_email = user_email
    end

    def filter_in( _reader, _timestamp, _event, _event_note, _class_name, id, raw_key_values )
      key_values = parse_key_values raw_key_values
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "key_values=#{key_values.pretty_inspect}",
                                             "@email=#{@user_email}",
                                             "key_values['user_email']=#{key_values['user_email']}",
                                             "" ] if email_log_filter_debug_verbose
      @user_email == key_values['user_email']
    end

  end

  class IdLogFilter < AbstractLogFilter

    attr_reader :matching_ids

    def initialize( matching_ids: [], options: {} )
      super( options: options )
      @matching_ids = arg_to_array matching_ids
    end

    def filter_in( _reader, _timestamp, _event, _event_note, _class_name, id, _raw_key_values )
      @matching_ids.include? id
    end

    def filter_in_child_id( raw_key_values )
      key_values = parse_key_values raw_key_values
      child_id = key_values['child_id']
      return false if child_id.blank?
      @matching_ids.include? child_id
    end

    def filter_in_parent_id( raw_key_values )
      key_values = parse_key_values raw_key_values
      parent_id = key_values['parent_id']
      return false if parent_id.blank?
      @matching_ids.include? parent_id
    end

    def filter_in_parent_or_child_id( raw_key_values )
      key_values = parse_key_values raw_key_values
      id = key_values['parent_id']
      return true if id.present? && @matching_ids.include?( id )
      id = key_values['child_id']
      return false if id.blank?
      @matching_ids.include? id
    end

  end

  class ChildIdLogFilter < IdLogFilter

    def initialize( matching_ids: [], options: {} )
      super( matching_ids: matching_ids, options: options )
    end

    def filter_in( _reader, _timestamp, _event, _event_note, _class_name, _id, raw_key_values )
      filter_in_child_id raw_key_values
    end

  end

  class IdOrParentIdLogFilter < IdLogFilter

    def initialize( matching_ids: [], options: {} )
      super( matching_ids: matching_ids , options: options)
    end

    def filter_in( reader, timestamp, event, event_note, class_name, id, raw_key_values )
      return true if super.filter_in( reader, timestamp, event, event_note, class_name, id, raw_key_values )
      filter_in_parent_id raw_key_values
    end

  end

  class IdOrParentOrChildIdLogFilter < IdLogFilter

    def initialize( matching_ids: [], options: {} )
      super( matching_ids: matching_ids, options: options )
    end

    def filter_in( reader, timestamp, event, event_note, class_name, id, raw_key_values )
      return true if super.filter_in( reader, timestamp, event, event_note, class_name, id, raw_key_values )
      filter_in_parent_or_child_id raw_key_values
    end

  end

  class ParentIdLogFilter < IdLogFilter

    def initialize( matching_ids: [], options: {} )
      super( matching_ids: matching_ids, options: options )
    end

    def filter_in( _reader, _timestamp, _event, _event_note, _class_name, _id, raw_key_values )
      filter_in_parent_id raw_key_values
    end

  end

end
# rubocop:enable Metrics/ParameterLists
