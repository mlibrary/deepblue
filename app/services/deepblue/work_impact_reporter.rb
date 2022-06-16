# frozen_string_literal: true

module Deepblue

  require_relative './abstract_reporter'

  class WorkImpactReporter < AbstractReporter

    DEFAULT_REPORT_DIR = nil unless const_defined? :DEFAULT_REPORT_DIR
    DEFAULT_REPORT_FILE_PREFIX = nil unless const_defined? :DEFAULT_REPORT_FILE_PREFIX
    DEFAULT_REPORT_QUIET = true unless const_defined? :DEFAULT_REPORT_QUIET

    class Datum

      attr_accessor :id, :create_date, :update_date, :total_file_size

      def initialize( work )
        @id = work.id
        @create_date = work.create_date # TODO: validate
        @update_date = work.update_date # TODO: validate
        @total_file_size = work.total_file_size
      end

    end

    # attr_accessor :data_set_ids
    # attr_accessor :file_set_ids

    attr_accessor :data
    attr_accessor :date_filter

    # do the date_filter as options

    def initialize( msg_handler:, options: {} )
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
      @report_dir = expand_path_partials( report_dir )

      # TODO: filtering for date
      DataSet.all.each do |work|
        @data << Datum.new( work )
      end
      msg_handler.msg_verbose "#{@data.size} works found." # using filter
      @data.sort! do |a,b|
        a.create_date < b.create_date # verify this operation
      end

      # TODO: done if @data is empty

      @prefix = task_options_value( key: 'report_file_prefix', default_value: DEFAULT_REPORT_FILE_PREFIX )
      @prefix = "#{Time.now.strftime('%Y%m%d')}_work_impact_report" if @prefix.nil?
      @prefix = expand_path_partials( @prefix )
      @report_file = Pathname.new( @report_dir ).join "#{prefix}.txt" # TODO: should be csv file
      # File.open( report_file, 'w' ) { |f| f << report << "\n" }
      msg_handler.msg "Report file: #{@report_file}"

      # earliest date should be in @data[0].create_date
      first_date = @data[0].create_date

      msg_handler.msg_verbose "First date: #{}"


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
