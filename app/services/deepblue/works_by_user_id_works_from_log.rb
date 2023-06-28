# frozen_string_literal: true

module Deepblue

  require_relative './log_extracter'
  require_relative './log_filter'

  # rubocop:disable Metrics/ParameterLists
  class WorksByUserIdWorksFromLog < LogExtracter

    mattr_accessor :works_by_user_id_works_from_log, default: true

    attr_reader :works_by_user_id_ids, :works_by_user_id_to_key_values_map

    # def initialize( filter: DataSetLogFilter.new, input:, options: {} )
    def initialize( email:, filter: nil, input:, options: {} )
      super( filter: UserEmailLogFilter.new( user_email: email, options: options ),
             input: input,
             extract_parsed_tuple: true,
             options: options )

      filter = UserEmailLogFilter.new( user_email: email, options: options ) if filter.blank?
      filter_and( new_filters: filter ) if filter.present?
    end

    def run
      super
      filter = self.filter
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "filter=#{filter}",
                                             "" ] if works_by_user_id_works_from_log
      @works_by_user_id_ids = []
      @works_by_user_id_to_key_values_map = {}
      lines = lines_extracted
      lines.each do |tuple|
        # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
        #                                        ::Deepblue::LoggingHelper.called_from,
        #                                        "tuple=#{tuple}",
        #                                        "" ] if works_by_user_id_works_from_log
        _line, timestamp, event, event_note, class_name, id, raw_key_values = tuple
        next if filter.present? && !filter.filter_in( self,
                                                      timestamp,
                                                      event,
                                                      event_note,
                                                      class_name,
                                                      id,
                                                      raw_key_values )
        # key_values = ProvenanceHelper.parse_log_line_key_values raw_key_values
        puts "#{timestamp}, #{event}, #{event_note}, #{class_name}, #{id}" if verbose
        unless @works_by_user_id_to_key_values_map.key? id
          @works_by_user_id_ids << id
          # puts "#{id} raw_key_values=#{raw_key_values}"
          key_values = ProvenanceHelper.parse_log_line_key_values raw_key_values
          # puts "#{id} key_values=#{key_values}"
          @works_by_user_id_to_key_values_map[id] = key_values
        end
      end
    end

  end
  # rubocop:enable Metrics/ParameterLists

end
