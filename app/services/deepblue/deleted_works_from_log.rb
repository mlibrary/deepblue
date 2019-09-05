# frozen_string_literal: true

module Deepblue

  require_relative './log_extracter'
  require_relative './log_filter'
  require_relative  '../../models/concerns/deepblue/abstract_event_behavior.rb'

  # rubocop:disable Metrics/ParameterLists
  class DeletedWorksFromLog < LogExtracter

    class DeletedLogFilter < EventLogFilter

      def initialize( options: {} )
        super( matching_events: [ AbstractEventBehavior::EVENT_DESTROY ], options: options )
      end

    end

    attr_reader :deleted_ids, :deleted_id_to_key_values_map

    # def initialize( filter: DataSetLogFilter.new, input:, options: {} )
    def initialize( filter: nil, input:, options: {} )
      super( filter: DeletedLogFilter.new( options: options ), input: input, extract_parsed_tuple: true, options: options )
      filter = DataSetLogFilter.new( options: options ) if filter.blank?
      filter_and( new_filters: filter ) if filter.present?
    end

    def run
      super
      @deleted_ids = []
      @deleted_id_to_key_values_map = {}
      lines = lines_extracted
      lines.each do |tuple|
        _line, timestamp, event, event_note, class_name, id, raw_key_values = tuple
        # key_values = ProvenanceHelper.parse_log_line_key_values raw_key_values
        puts "#{timestamp}, #{event}, #{event_note}, #{class_name}, #{id}" if verbose
        unless @deleted_id_to_key_values_map.key? id
          @deleted_ids << id
          # puts "#{id} raw_key_values=#{raw_key_values}"
          key_values = ProvenanceHelper.parse_log_line_key_values raw_key_values
          # puts "#{id} key_values=#{key_values}"
          @deleted_id_to_key_values_map[id] = key_values
        end
      end
    end

  end
  # rubocop:enable Metrics/ParameterLists

end
