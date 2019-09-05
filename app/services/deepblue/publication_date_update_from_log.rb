# frozen_string_literal: true

module Deepblue

  require_relative './log_filter'
  require_relative './log_extracter'
  require_relative  '../../models/concerns/deepblue/abstract_event_behavior.rb'

  # rubocop:disable Metrics/ParameterLists
  class PublicationDateUpdateFromLog < LogExtracter

    class PublishedLogFilter < EventLogFilter

      def initialize
        super( matching_events: [ AbstractEventBehavior::EVENT_PUBLISH ] )
      end

    end

    attr_reader :published_id, :published_id_to_key_values_map

    def initialize( filter: nil, input:, options: {} )
      super( filter: PublishedLogFilter.new, input: input, extract_parsed_tuple: true, options: options )
      filter_and( new_filters: filter ) if filter.present?
    end

    def run
      super
      lines = lines_extracted
      lines.each do |tuple|
        _line, timestamp, _event, _event_note, _class_name, id, _raw_key_values = tuple
        # key_values = ProvenanceHelper.parse_log_line_key_values raw_key_values
        date = timestamp
        date = DateTime.parse date if date.is_a? String
        begin
          work = ActiveFedora::Base.find id
          next unless work.respond_to? :date_published
          if work.date_published.blank?
            puts "#{work.id}: setting date_published to #{date}" if verbose
            work.date_published = date
            work.date_modified = DateTime.now
            work.save!
          elsif work.date_published < date
            puts "#{work.id}: updating date_published from #{work.date_published} to #{date}" if verbose
            work.date_published = date
            work.date_modified = DateTime.now
            work.save!
          else
            puts "#{work.id}: skipping old date_published" if verbose
          end
        rescue ActiveFedora::ObjectNotFoundError
          puts "#{id}: work not found"
        end
      end
    end

  end
  # rubocop:enable Metrics/ParameterLists

end
