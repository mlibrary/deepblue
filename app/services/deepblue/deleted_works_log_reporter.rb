# frozen_string_literal: true

module Deepblue

  require_relative './log_filter'
  require_relative './log_reporter'
  require_relative  '../../models/concerns/deepblue/abstract_event_behavior.rb'

  # rubocop:disable Metrics/ParameterLists
  class DeletedWorksLogReporter < LogReporter

    class DeletedLogFilter < EventLogFilter

      def initialize( options: {} )
        super( matching_events: [ AbstractEventBehavior::EVENT_DESTROY ], options: options )
      end

    end

    attr_reader :deleted_ids, :deleted_id_to_key_values_map

    def initialize( filter: nil, input:, options: {} )
      super( filter: DeletedLogFilter.new( options: options ), input: input, options: options )
      filter = DataSetLogFilter.new( options: options ) if filter.blank?
      filter_and( new_filters: filter ) if filter.present?
    end

    # rubocop:disable Rails/Output
    def report
      run
      puts "timestamp_first = #{timestamp_first}" if verbose
      puts "timestamp_last = #{timestamp_last}" if verbose
      # puts "ids = #{ids}"
      # puts "events = #{events}"
      # puts "class_events = #{class_events}"
      puts "deleted_ids.size = #{deleted_ids.size}" if verbose
      map = deleted_id_to_key_values_map
      puts "id,deleted,event_note,url,authoremail,creator"
      deleted_ids.each do |id|
        key_values = map[id]
        timestamp = key_values['timestamp']
        url = "https://deepbluedata.lib.umich.edu/provenance_log/#{id}"
        authoremail = key_values["authoremail"]
        event_note = key_values["event_note"]
        creator = key_values["creator"]
        creator = creator.join(";") if creator.present? && creator.respond_to?( :join )
        puts "\"#{id}\",#{timestamp},#{event_note},#{url},#{authoremail},\"#{creator}\""
      end
    end
    # rubocop:enable Rails/Output

    protected

      def initialize_report_values
        super()
        @deleted_ids = []
        @deleted_id_to_key_values_map = {}
      end

      def line_read( line, timestamp, event, event_note, class_name, id, raw_key_values )
        super( line, timestamp, event, event_note, class_name, id, raw_key_values )
        @deleted_ids << id
        # puts "#{id} raw_key_values=#{raw_key_values}"
        key_values = ProvenanceHelper.parse_log_line_key_values raw_key_values
        # puts "#{id} key_values=#{key_values}"
        @deleted_id_to_key_values_map[id] = key_values
      end

  end
  # rubocop:enable Metrics/ParameterLists

end
