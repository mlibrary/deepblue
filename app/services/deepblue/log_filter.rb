# frozen_string_literal: true

# rubocop:disable Metrics/ParameterLists
module Deepblue

  class AbstractArrayOfFilters

    attr_reader :filters

    def initialize( filters: [] )
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

    def initialize( filters: [] )
      super( filters: filters )
    end

    def and( new_filters: )
      add_filters( new_filters: new_filters )
    end

    def or( new_filters: )
      new_filter = OrLogFilter.new( filters: self ).add_filters( new_filters: new_filters )
      return new_filter
    end

    def filter_in( timestamp, event, event_note, class_name, id, raw_key_values )
      filters.each do |filter|
        return false unless filter.filter_in( timestamp, event, event_note, class_name, id, raw_key_values )
      end
      return true
    end

  end

  class OrLogFilter < AbstractArrayOfFilters

    def initialize( filters: [] )
      super( filters: filters )
    end

    def and( new_filters: )
      new_filter = AndLogFilter.new( filters: self ).add_filters( new_filters: new_filters )
      return new_filter
    end

    def or( new_filters: )
      add_filters( new_filters: new_filters )
    end

    def filter_in( timestamp, event, event_note, class_name, id, raw_key_values )
      filters.each do |filter|
        return true if filter.filter_in( timestamp, event, event_note, class_name, id, raw_key_values )
      end
      return false
    end

  end

  class AbstractLogFilter

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

    def filter_in( _timestamp, _event, _event_note, _class_name, _id, _raw_key_values )
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
        if timestamp_format.blank?
          return DateTime.strptime( arg, "%Y-%m-%d %H:%M:%S" ) if arg.match?( /\d\d\d\d\-\d\d?\-\d\d? \d\d?:\d\d:\d\d/ )
          return DateTime.strptime( arg, "%m/%d/%Y" ) if arg.match?( /\d\d?\/\d\d?\/\d\d\d\d/ )
          return DateTime.strptime( arg, "%m-%d-%Y" ) if arg.match?( /\d\d?\-\d\d?\-\d\d\d\d/ )
          return DateTime.strptime( arg, "%Y" ) if arg.match?( /\d\d\d\d/ )
          timestamp = DateTime.parse( arg ) if arg.is_a? String
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

    def initialize( filter: )
      @filter = filter
    end

    def filter_in( timestamp, event, event_note, class_name, id, raw_key_values )
      rv = @filter.filter_in( timestamp, event, event_note, class_name, id, raw_key_values )
      return !rv
    end

  end

  class AllLogFilter < AbstractLogFilter

    def all_log_filter?
      true
    end

    def filter_in( _timestamp, _event, _event_note, _class_name, _id, _raw_key_values )
      true
    end

  end

  class ClassNameLogFilter < AbstractLogFilter

    attr_reader :matching_class_names

    def initialize( matching_class_names: [] )
      @matching_classe_names = arg_to_array matching_class_names
    end

    def filter_in( _timestamp, _event, _event_note, _class_name, _id, _raw_key_values )
      @matching_classe_names.include? event
    end

  end

  class CollectionLogFilter < ClassNameLogFilter

    def initialize
      super( matching_class_names: [ Collection.name ] )
    end

  end

  class DataSetLogFilter < ClassNameLogFilter

    def initialize
      super( matching_class_names: [ DataSet.name ] )
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
    def initialize( begin_timestamp: nil, end_timestamp: nil, timestamp_format: '' )
      @begin_timestamp = arg_to_timestamp( begin_timestamp, timestamp_format: timestamp_format )
      @end_timestamp = arg_to_timestamp( end_timestamp, timestamp_format: timestamp_format )
    end

    def filter_in( timestamp, _event, _event_note, _class_name, _id, _raw_key_values )
      before_begin = false
      before_begin = timestamp < @begin_timestamp if @begin_timestamp.present?
      after_end = false
      after_end = timestamp > @after_timestamp if @after_timestamp.present?
      return !before_begin && !after_end
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

    def initialize( matching_events: [] )
      @matching_events = arg_to_array matching_events
    end

    def filter_in( _timestamp, event, _event_note, _class_name, _id, _raw_key_values )
      @matching_events.include? event
    end

  end

  class CreateOrDestroyLogFilter < EventLogFilter

    def initialize
      super( matching_events: [ AbstractEventBehavior::EVENT_CREATE, AbstractEventBehavior::EVENT_DESTROY ] )
    end

  end

  class FileSetFilter < ClassNameLogFilter

    def initialize
      super( matching_class_names: [ FileSet.name ] )
    end

  end

  class FixityCheckLogFilter < EventLogFilter

    def initialize
      super( matching_events: [ AbstractEventBehavior::EVENT_FIXITY_CHECK ] )
    end

  end

  class MigrationEventFilter < EventLogFilter

    def initialize
      super( matching_events: [ AbstractEventBehavior::EVENT_CHILD_ADD,
                                AbstractEventBehavior::EVENT_FIXITY_CHECK,
                                AbstractEventBehavior::EVENT_INGEST,
                                AbstractEventBehavior::EVENT_MIGRATE,
                                AbstractEventBehavior::EVENT_VIRUS_SCAN ] )
    end

  end

  class IdLogFilter < AbstractLogFilter

    attr_reader :matching_ids

    def initialize( matching_ids: [] )
      @matching_ids = arg_to_array matching_ids
    end

    def filter_in( _timestamp, _event, _event_note, _class_name, id, _raw_key_values )
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

    def initialize( matching_ids: [] )
      super( matching_ids: matching_ids )
    end

    def filter_in( _timestamp, _event, _event_note, _class_name, _id, raw_key_values )
      filter_in_child_id raw_key_values
    end

  end

  class IdOrParentIdLogFilter < IdLogFilter

    def initialize( matching_ids: [] )
      super( matching_ids: matching_ids )
    end

    def filter_in( timestamp, event, event_note, class_name, id, raw_key_values )
      return true if super.filter_in( timestamp, event, event_note, class_name, id, raw_key_values )
      filter_in_parent_id raw_key_values
    end

  end

  class IdOrParentOrChildIdLogFilter < IdLogFilter

    def initialize( matching_ids: [] )
      super( matching_ids: matching_ids )
    end

    def filter_in( timestamp, event, event_note, class_name, id, raw_key_values )
      return true if super.filter_in( timestamp, event, event_note, class_name, id, raw_key_values )
      filter_in_parent_or_child_id raw_key_values
    end

  end

  class ParentIdLogFilter < IdLogFilter

    def initialize( matching_ids: [] )
      super( matching_ids: matching_ids )
    end

    def filter_in( _timestamp, _event, _event_note, _class_name, _id, raw_key_values )
      filter_in_parent_id raw_key_values
    end

  end

end
# rubocop:enable Metrics/ParameterLists
