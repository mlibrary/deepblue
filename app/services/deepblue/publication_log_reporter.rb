# frozen_string_literal: true

module Deepblue

  require_relative './log_filter'
  require_relative './log_reporter'
  require_relative  '../../models/concerns/deepblue/abstract_event_behavior.rb'

  # rubocop:disable Metrics/ParameterLists
  class PublicationLogReporter < LogReporter

    class PublishedLogFilter < EventLogFilter

      def initialize
        super( matching_events: [ AbstractEventBehavior::EVENT_PUBLISH ] )
      end

    end

    attr_reader :published_id, :published_id_to_key_values_map

    def initialize( filter: nil, input:, options: {} )
      super( filter: PublishedLogFilter.new, input: input, options: options )
      filter_and( new_filters: filter ) if filter.present?
    end

    # rubocop:disable Rails/Output
    def report
      run
      # TODO: pretty output
      puts "timestamp_first = #{timestamp_first}"
      puts "timestamp_last = #{timestamp_last}"
      # puts "ids = #{ids}"
      # puts "events = #{events}"
      # puts "class_events = #{class_events}"
      puts "published_id.size = #{published_id.size}"
      #puts "published_id_map = #{fixity_check_failed_id.size}"
      map = published_id_to_key_values_map
      puts "id,published,url,authoremail,creator,subject_discipline,primary filetype"
      published_id.each do |id|
        key_values = map[id]
        timestamp = key_values['timestamp']
        url = "https://deepbluedata.lib.umich.edu/data/concern/data_sets/#{id}"
        authoremail = key_values["authoremail"]
        creator = key_values["creator"]
        # creator = creator.gsub( /[\[\]]/, '' ) if creator.present?
        # creator = creator.gsub( /"/, "'") if creator.present?
        creator = creator.join(";") if creator.present? && creator.respond_to?( :join )
        subject_discipline = key_values["subject_discipline"]
        # subject_discipline = subject_discipline.gsub( /[\[\]]/, '' ) if subject_discipline.present?
        # subject_discipline = subject_discipline.gsub( /"/, '' ) if subject_discipline.present?
        subject_discipline = subject_discipline.join(";") if subject_discipline.present? && subject_discipline.respond_to?( :join )
        puts "\"#{id}\",#{timestamp},#{url},#{authoremail},\"#{creator}\",\"#{subject_discipline}\""
      end
    end
    # rubocop:enable Rails/Output

    protected

      def initialize_report_values
        super()
        @published_id = []
        @published_id_to_key_values_map = {}
      end

      def line_read( line, timestamp, event, event_note, class_name, id, raw_key_values )
        super( line, timestamp, event, event_note, class_name, id, raw_key_values )
        @published_id << id
        # puts "#{id} raw_key_values=#{raw_key_values}"
        key_values = ProvenanceHelper.parse_log_line_key_values raw_key_values
        # puts "#{id} key_values=#{key_values}"
        @published_id_to_key_values_map[id] = key_values
      end

  end
  # rubocop:enable Metrics/ParameterLists

end
