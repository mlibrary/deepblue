# frozen_string_literal: true

module Deepblue

  require 'csv'
  require_relative './log_filter'
  require_relative './log_reporter'

  # rubocop:disable Metrics/ParameterLists
  class MigrationLogReporter < LogReporter

    DEFAULT_EXPECTED_IDS_PATHNAME = nil

    attr_accessor :collection_ids, :file_set_ids, :work_ids

    attr_accessor :fixity_check_failed_ids, :fixity_check_passed_ids

    attr_accessor :expected_ids, :expected_ids_pathname

    attr_accessor :expected_collection_ids,
                  :missing_collection_ids,
                  :unexpected_collection_ids,
                  :expected_work_ids,
                  :missing_work_ids,
                  :unexpected_work_ids,
                  :expected_file_set_ids,
                  :missing_file_set_ids,
                  :unexpected_file_set_ids


    def initialize( filter: nil, input:, options: {} )
      super( filter: Deepblue::MigrationEventFilter.new, input: input, options: options )
      filter_and( new_filters: filter ) if filter.present?
      @expected_ids_pathname = option( key: 'expected_ids_pathname', default_value: DEFAULT_EXPECTED_IDS_PATHNAME )
    end

    # rubocop:disable Rails/Output
    def report
      run
      run_rest
      # TODO: pretty output
      puts "timestamp_first = #{timestamp_first}"
      puts "timestamp_last = #{timestamp_last}"
      puts "ids.count = #{ids.count}"
      puts "events.count = #{events.count}"
      puts "class_events.count = #{class_events.count}"
      puts "class_events = #{class_events}"
      puts "migrated collection_ids.count=#{collection_ids.count}"
      puts "migrated work_ids.count=#{work_ids.count}"
      puts "migrated file_set_ids.count=#{file_set_ids.count}"
      puts "migrated file set fixity_check_failed_ids.count=#{fixity_check_failed_ids.count}"
      puts "migrated file set fixity_check_passed_ids.count=#{fixity_check_passed_ids.count}"
      puts "unexpected_collection_ids.count=#{unexpected_collection_ids.count} (out of #{collection_ids.count} migrated)"
      puts "missing_collection_ids.count=#{missing_collection_ids.count} (out of #{expected_collection_ids.count} expected)"
      puts "unexpected_work_ids.count=#{unexpected_work_ids.count} (out of #{work_ids.count} migrated)"
      puts "missing_work_ids.count=#{missing_work_ids.count} (out of #{expected_work_ids.count} expected)"
      puts "unexpected_file_set_ids.count=#{unexpected_file_set_ids.count} (out of #{file_set_ids.count} migrated)"
      puts "missing_file_set_ids.count=#{missing_file_set_ids.count} (out of #{expected_file_set_ids.count} expected)"
    end
    # rubocop:enable Rails/Output

    protected

      def expected_collections_csv_file
        # TODO: generalize and parameterize this
        "./log/20180911_collections_report_collections.csv"
      end

      def expected_file_sets_csv_file
        # TODO: generalize and parameterize this
        "./log/20180911_collections_report_file_sets.csv"
      end

      def expected_works_csv_file
        # TODO: generalize and parameterize this
        "./log/20180911_collections_report_works.csv"
      end

      def initialize_expected
        initialize_expected_collection_ids
        initialize_expected_work_ids
        initialize_expected_file_set_ids
      end

      # def load_expected_ids
      #   @expected_ids = {}
      #   return if expected_ids_pathname.blank?
      #   return if File.exist? expected_ids_pathname
      #   # file in form: id,type,children ids space separated
      #   # TODO load the file
      # end

      def initialize_expected_collection_ids
        @expected_collection_ids = {}
        CSV.foreach( expected_collections_csv_file ) do |row|
          id = row[0]
          col_work_ids = row[10]
          work_ids = {}
          if col_work_ids.present?
            col_work_ids = col_work_ids.split( ' ' )
            col_work_ids.each do |wid|
              work_ids[wid] = true
            end
          end
          @expected_collection_ids[id] = true
        end
      end

      def initialize_expected_file_set_ids
        @expected_file_set_ids = {}
        CSV.foreach( expected_file_sets_csv_file ) do |row|
          id = row[0]
          parent_work_id = row[1]
          @expected_file_set_ids[id] = parent_work_id
        end
      end

      def initialize_expected_work_ids
        @expected_work_ids = {}
        CSV.foreach( expected_works_csv_file ) do |row|
          id = row[0]
          col_parent_ids = row[8]
          parent_ids = {}
          if col_parent_ids.present?
            col_parent_ids = col_parent_ids.split( ' ' )
            col_parent_ids.each do |pid|
              parent_ids[pid] = true
            end
          end
          @expected_work_ids[id] = parent_ids
        end
      end

      def initialize_report_values
        super()
        initialize_expected
        @collection_ids = {}
        @file_set_ids = {}
        @work_ids = {}
        @fixity_check_failed_ids = []
        @fixity_check_passed_ids = []
        @missing_collection_ids = []
        @unexpected_collection_ids = []
        @missing_work_ids = []
        @unexpected_work_ids = []
        @missing_file_set_ids = []
        @unexpected_file_set_ids = []
      end

      def line_read( line, timestamp, event, event_note, class_name, id, raw_key_values )
        super( line, timestamp, event, event_note, class_name, id, raw_key_values )
        @raw_key_values = raw_key_values
        @key_values = nil
        case event
        when AbstractEventBehavior::EVENT_MIGRATE
          register_migrate( timestamp, event, event_note, class_name, id )
        when AbstractEventBehavior::EVENT_INGEST
          register_ingest( timestamp, event, event_note, class_name, id )
        when AbstractEventBehavior::EVENT_CHILD_ADD
          register_ingest( timestamp, event, event_note, class_name, id )
        when AbstractEventBehavior::EVENT_FIXITY_CHECK
          register_fixity_check( timestamp, event, event_note, class_name, id )
        when AbstractEventBehavior::EVENT_VIRUS_SCAN
          register_virus_scan( timestamp, event, event_note, class_name, id )
        end
      end

      def register_child_add( timestamp, event, event_note, class_name, id )
        # todo
      end

      def register_fixity_check( _timestamp, _event, event_note, _class_name, id )
        if 'success' == event_note
          @fixity_check_passed_ids << id
        else
          @fixity_check_failed_ids << id
        end
      end

      def register_ingest( timestamp, event, event_note, class_name, id )
        # todo
      end

      def register_migrate( _timestamp, _event, _event_note, class_name, id )
        case class_name
        when 'FileSet'
          @file_set_ids[id] = true unless @file_set_ids.key? id
        when 'DataSet'
          @work_ids[id] = true unless @work_ids.key? id
        when 'Collection'
          @collection_ids[id] = true unless @collection_ids.key? id
        end
      end

      def register_virus_scan( timestamp, event, event_note, class_name, id )
        # todo
      end

      def run_rest
        @expected_collection_ids.each_key do |id|
          @missing_collection_ids << id unless @collection_ids.key? id
        end
        @expected_work_ids.each_key do |id|
          @missing_work_ids << id unless @work_ids.key? id
        end
        @expected_file_set_ids.each_key do |id|
          @missing_file_set_ids << id unless @file_set_ids.key? id
        end
        @collection_ids.each_key do |id|
          @unexpected_collection_ids << id unless @expected_collection_ids.key? id
        end
        @work_ids.each_key do |id|
          @unexpected_work_ids << id unless @expected_work_ids.key? id
        end
        @file_set_ids.each_key do |id|
          @unexpected_file_set_ids << id unless @expected_file_set_ids.key? id
        end
      end

  end
  # rubocop:enable Metrics/ParameterLists

end
