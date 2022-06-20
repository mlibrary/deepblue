# frozen_string_literal: true

module Deepblue

  require_relative './abstract_reporter'

  class WorkImpactReporter < AbstractReporter

    mattr_accessor :work_impact_reporter_debug_verbose, default: false

    DEFAULT_REPORT_DIR = nil unless const_defined? :DEFAULT_REPORT_DIR
    DEFAULT_REPORT_FILE_PREFIX = nil unless const_defined? :DEFAULT_REPORT_FILE_PREFIX
    DEFAULT_REPORT_QUIET = true unless const_defined? :DEFAULT_REPORT_QUIET

    class Datum

      attr_accessor :id, :create_date, :date_modified, :date_published, :total_file_size

      def initialize( work )
        @id = work.id
        @create_date = work.create_date
        @date_modified = work.date_modified
        @date_published = work.date_published
        @total_file_size = work.total_file_size
      end

    end

    # attr_accessor :data_set_ids
    # attr_accessor :file_set_ids

    attr_accessor :data
    attr_accessor :date_filter

    # do the date_filter as options

    def initialize( msg_handler:, options: {} )
      msg_handler.debug_verbose = msg_handler.debug_verbose || work_impact_reporter_debug_verbose
      super( msg_handler: msg_handler, options: options )
      @data = []
      # @date_filter = date_filter
    end

    def initialize_report_values
      super
    end

    def report

      @report_dir = task_options_value( key: 'report_dir', default_value: DEFAULT_REPORT_DIR )
      unless @report_dir.present?
        msg_handler.msg_warn "No report directory found. (key: 'report_dir')"
        return
      end
      @report_dir = ReportHelper.expand_path_partials( @report_dir )

      # TODO: filtering for date
      DataSet.all.each do |work|
        @data << Datum.new( work )
        msg_handler.bold_debug [ "@data.last.id = #{@data.last.id}",
                                 "@data.last.create_date = #{@data.last.create_date}",
                                 "@data.last.date_modified = #{@data.last.date_modified}",
                                 "@data.last.date_published = #{@data.last.date_published}",
                                 "@data.last.total_file_size = #{@data.last.total_file_size}",
                                 "" ]
      end
      msg_handler.msg_verbose "#{@data.size} works found." # using filter
      # @data.sort! do |a,b|
      #   a.create_date < b.create_date # verify this operation
      # end

      @data.sort_by!(&:create_date)

      # earliest date should be in @data[0].create_date
      first_date = @data[0].create_date
      msg_handler.msg_verbose "First date: #{first_date}"

      # TODO: done if @data is empty

      @prefix = task_options_value( key: 'report_file_prefix', default_value: DEFAULT_REPORT_FILE_PREFIX )
      @prefix = "#{Time.now.strftime('%Y%m%d')}_work_impact_report" if @prefix.nil?
      @prefix = ReportHelper.expand_path_partials( @prefix )
      @report_file = Pathname.new( @report_dir ).join "#{@prefix}.txt" # TODO: should be csv file
      msg_handler.msg "Report file: #{@report_file}"

      # TODO: convert this to CSV file
      File.open( @report_file, 'w' ) do |f|
        @data.each do |d|
          f << "#{d.id},#{d.create_date},#{d.date_modified},#{d.date_published},#{d.total_file_size}\n"
        end
      end

      # report_section_data_set( header: "Data sets with pending doi:", ids: data_set_ids )
      # report_section_file_set( header: "File sets with pending doi:", ids: file_set_ids )
    end

    def month_span( date )
      return [date.as_start_of_month, date.as_end_of_month]
    end

    def next_month( date )
      return date + 1.month
    end

    # def report_section_data_set( header:, ids: )
    #   return if hash.nil?
    #   return if quiet && !hash.present?
    #   r_header( header )
    #   unless ids.present?
    #     r_line "None."
    #   else
    #     r_list_begin( 'ul' )
    #     ids.each_key do |id|
    #       r_list_item( ::Deepblue::EmailHelper.data_set_url( id: id ), as_link: true )
    #     end
    #     r_list_end( 'ul' )
    #   end
    # end
    #
    # def report_section_file_set( header:, ids: )
    #   return if hash.nil?
    #   return if quiet && !hash.present?
    #   r_header( header )
    #   unless ids.present?
    #     r_line "None."
    #   else
    #     r_list_begin( 'ul' )
    #     ids.each_key do |id|
    #       r_list_item( ::Deepblue::EmailHelper.file_set_url( id: id ), as_link: true )
    #     end
    #     r_list_end( 'ul' )
    #   end
    # end

  end

end
