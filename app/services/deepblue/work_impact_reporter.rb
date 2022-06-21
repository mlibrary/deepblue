# frozen_string_literal: true

module Deepblue

  require_relative './abstract_reporter'

  class WorkImpactReporter < AbstractReporter

    mattr_accessor :work_impact_reporter_debug_verbose, default: false

    DEFAULT_REPORT_DIR = nil unless const_defined? :DEFAULT_REPORT_DIR
    DEFAULT_REPORT_FILE_PREFIX = nil unless const_defined? :DEFAULT_REPORT_FILE_PREFIX
    DEFAULT_REPORT_QUIET = true unless const_defined? :DEFAULT_REPORT_QUIET

    class WorkDatum

      # TODO: draft status?

      attr_accessor :id, :create_date, :date_modified, :date_published, :file_set_ids, :total_file_size, :visibility

      def initialize( work )
        @id = work.id
        @create_date = work.create_date
        @date_modified = work.date_modified
        @date_published = work.date_published
        @file_set_ids = work.file_set_ids
        @total_file_size = WorkImpactReporter.to_integer(work.total_file_size)
        @visibility = work.visibility
      end

    end

    class FileSetDatum

      attr_accessor :id, :parent_id, :create_date, :date_modified, :date_published, :file_size, :visibility

      def initialize( file_set, parent: )
        @id = file_set.id
        @parent_id = parent.id
        @create_date = file_set.create_date
        @date_modified = file_set.date_modified
        @date_published = parent.date_published
        @file_size = WorkImpactReporter.to_integer(MetadataHelper.file_set_file_size file_set)
        @visibility = parent.visibility
      end

    end

    def self.to_integer( x )
      return 0 if x.blank?
      x.to_i
    end

    attr_accessor :work_data
    attr_accessor :file_set_data
    attr_accessor :date_filter
    attr_reader :begin_date, :end_date

    # do the date_filter as options

    def initialize( msg_handler:, options: {} )
      msg_handler.debug_verbose = msg_handler.debug_verbose || work_impact_reporter_debug_verbose
      super( msg_handler: msg_handler, options: options )
      @work_data = []
    end

    def initialize_report_values
      super
    end

    def initialize_date_filter
      @begin_date = to_datetime( date: task_options_value( key: 'begin_date', default_value: nil ) )
      @end_date = to_datetime( date: task_options_value( key: 'end_date', default_value: nil ) )
      normalize_begin_end_dates
      @date_filter = filter_range
      msg_handler.msg_verbose "filter range: #{@date_filter}"
    end

    def initialize_prefix
      @prefix = task_options_value( key: 'report_file_prefix', default_value: DEFAULT_REPORT_FILE_PREFIX )
      @prefix = "#{Time.now.strftime('%Y%m%d')}_work_impact_report" if @prefix.nil?
      @prefix = ReportHelper.expand_path_partials( @prefix )
      msg_handler.msg_verbose "prefix: '#{@prefix}'"
    end

    def initialize_report_dir
      @report_dir = task_options_value( key: 'report_dir', default_value: DEFAULT_REPORT_DIR )
      @report_dir = ReportHelper.expand_path_partials( @report_dir )
      msg_handler.msg_verbose "report_dir: '#{@report_dir}'"
    end

    def report
      initialize_date_filter
      initialize_prefix
      initialize_report_dir
      unless @report_dir.present?
        msg_handler.msg_warn "No report directory found. (key: 'report_dir')"
        return
      end

      load_works
      file_report( csv_header: %w[original_order id create_date date_modified date_published visibility file_set_count total_file_size],
                   data_array: @work_data,
                   extract: ->(d,i) { [i,
                                       d.id,
                                       d.create_date,
                                       d.date_modified,
                                       d.date_published,
                                       d.visibility,
                                       d.file_set_ids.size,
                                       d.total_file_size] },
                   filename: report_filename )
      work_monthly_report( csv_header: %w[original_order month_begin_date works_created file_set_count total_file_size],
                           date_extractor: ->(datum) { datum.create_date },
                           output_file: report_filename( postfix: "_monthly_created" ),
                           data_array: @work_data )
      data = select_published( @work_data )
      work_monthly_report( csv_header: %w[original_order month_begin_date works_published file_set_count total_file_size],
                           date_extractor: ->(datum) { datum.date_published },
                           output_file: report_filename( postfix: "_monthly_published" ),
                           data_array: data )
      data = load_file_sets
      file_report( csv_header: %w[original_order id parent_id create_date date_modified date_published file_size],
                   data_array: data,
                   extract: ->(d,i) { [i,d.id,d.create_date,d.parent_id,d.date_modified,d.date_published,d.file_size] },
                   filename: report_filename( postfix: "_file_sets" ) )
      data = select_published( data )
      file_set_monthly_report( csv_header: %w[original_order month_begin_date file_sets_created total_file_size],
                               date_extractor: ->(datum) { datum.create_date },
                               output_file: report_filename( postfix: "_monthly_created_file_sets" ),
                               data_array: data )
    end

    def report_filename( postfix: '', ext: ".csv" )
      Pathname.new( @report_dir ).join( "#{@prefix}#{postfix}#{ext}" )
    end

    def file_report( csv_header:, data_array:, extract:, filename: )
      msg_handler.msg "Report file: #{filename}"
      CSV.open( filename, "w", {:force_quotes=>true} ) do |csv|
        csv << csv_header
        data_array.each_with_index do |d,i|
          csv << extract.call(d,i)
        end
      end
    end

    def file_set_monthly_report( csv_header:, date_extractor:, output_file:, data_array: )
      first_date = data_array[0].create_date
      msg_handler.msg_verbose "First date: #{first_date}"
      msg_handler.msg "Report file: #{output_file}"
      CSV.open( output_file, "w", {:force_quotes=>true} ) do |csv|
        csv << csv_header
        last_date = DateTime.now
        first_date = date_extractor.call(data_array[0])
        msg_handler.msg_verbose "First date: #{first_date}"
        # starting with the first_date found, create a month bracket
        # step through each month creating a month summary of file set counts
        begin_on = first_date.beginning_of_month.beginning_of_day
        end_on = begin_on.end_of_month.end_of_day
        month = 1
        index = 0
        datum = data_array[index]
        date = date_extractor.call(datum)
        while begin_on <= last_date # && (index < data_array.size)
          count_for_month = 0
          total_file_size = 0
          while (index < data_array.size) && (date <= end_on)
            count_for_month += 1
            total = datum.file_size
            total ||= 0
            # total = total.to_i if total.is_a? String
            total_file_size += total
            index += 1
            break if index >= data_array.size
            datum = data_array[index]
            date = date_extractor.call(datum)
          end
          csv << [month,begin_on,count_for_month,total_file_size]
          begin_on = begin_on.next_month
          end_on = begin_on.end_of_month.end_of_day
          month += 1
        end
      end
    end

    def filter_in( curation_concern )
      return true if @begin_date.nil? && @end_date.nil?
      date = curation_concern.create_date
      return true if filter_in_date( date )
      date = nil
      date = curation_concern.date_published if curation_concern.respond_to? :date_published
      filter_in_date( date )
    end

    def filter_in_date( date )
      return true if @begin_date.nil? && @end_date.nil?
      return date.present? && date >= @begin_date && date <= @end_date
    end

    def filter_range
      return 'all' if @begin_date.nil? && @end_date.nil?
      return "between #{@begin_date} and #{@end_date}"
    end

    def load_file_sets
      data = []
      @work_data.each do |d|
        d.file_set_ids.each do |fid|
          fs = FileSet.find fid # TODO catch errors
          data << FileSetDatum.new( fs, parent: d )
        end
      end
      data.sort_by!(&:create_date)
      msg_handler.msg_verbose "#{data.size} file_sets found."
      return data
    end

    def load_works
      @work_data = []
      DataSet.all.each do |work|
        msg_handler.bold_debug [ "work.id = #{work.id}",
                                 "work.create_date = #{work.create_date}",
                                 "work.date_modified = #{work.date_modified}",
                                 "work.date_published = #{work.date_published}",
                                 "work.file_set_ids.size = #{work.file_set_ids.size}",
                                 "work.total_file_size = #{work.total_file_size}",
                                 "" ]
        next unless filter_in( work )
        @work_data << WorkDatum.new( work )
      end
      msg_handler.msg_verbose "#{@work_data.size} works found."
      @work_data.sort_by!(&:create_date)
    end

    def month_span( date )
      return [date.as_start_of_month, date.as_end_of_month]
    end

    def next_month( date )
      return date.month_next
    end

    def normalize_begin_end_dates
      return if @begin_date.nil? && @end_date.nil?
      @begin_date = DateTime.now - 10.years if @begin_date.blank?
      @end_date = DateTime.now.end_of_day if @end_date.blank?
    end

    def select_published( data_array )
      data = data_array.select { |d| d.date_published.present? && filter_in_date( d.date_published ) }
      data.sort_by!(&:date_published)
      msg_handler.msg_verbose "#{data.size} published works found."
      return data
    end

    def work_monthly_report( csv_header:, date_extractor:, output_file:, data_array: )
      first_date = data_array[0].create_date
      msg_handler.msg_verbose "First date: #{first_date}"
      msg_handler.msg "Report file: #{output_file}"
      CSV.open( output_file, "w", {:force_quotes=>true} ) do |csv|
        csv << csv_header
        last_date = DateTime.now
        first_date = date_extractor.call(data_array[0])
        msg_handler.msg_verbose "First date: #{first_date}"
        # starting with the first_date found, create a month bracket
        # step through each month creating a month summary of work counts
        begin_on = first_date.beginning_of_month.beginning_of_day
        end_on = begin_on.end_of_month.end_of_day
        month = 1
        index = 0
        datum = data_array[index]
        date = date_extractor.call(datum)
        # step through month creating a month summary of total files created and total file sizes added
        while begin_on <= last_date # && (index < data_array.size)
          count_for_month = 0
          total_file_sets = 0
          total_file_size = 0
          while (index < data_array.size) && (date <= end_on)
            count_for_month += 1
            total_file_sets += datum.file_set_ids.size
            total = datum.total_file_size
            total ||= 0
            total_file_size += total
            index += 1
            break if index >= data_array.size
            datum = data_array[index]
            date = date_extractor.call(datum)
          end
          csv << [month,begin_on,count_for_month,total_file_sets,total_file_size]
          begin_on = begin_on.next_month
          end_on = begin_on.end_of_month.end_of_day
          month += 1
        end
      end
    end

  end

end
