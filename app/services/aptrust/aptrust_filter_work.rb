# frozen_string_literal: true

require_relative './aptrust'

module Aptrust

  class FilterIn
    def include?( work: )
      return true
    end
  end

  class FilterDate

    attr_accessor :filter

    def initialize( begin_date:, end_date: )
      if begin_date.present? || end_date.present?
        @filter = ::Deepblue::FindCurationConcernFilterDate.new( begin_date: begin_date, end_date: end_date )
      else
        @filter = nil
      end
    end

    def include?( work: )
      return true if @filter.nil?
      @filter.include? work.date_modified
    end

  end

  class FilterSize

    attr_accessor :debug_verbose
    attr_accessor :max_size
    attr_accessor :min_size

    def initialize( min_size: 1, max_size: )
      @max_size = max_size
      @min_size = min_size
      @min_size = 1 if @min_size < 1
      @max_size = @min_size if @max_size < @min_size
    end

    def include?( work: )
      cc_size = work.total_file_size
      return false if cc_size.nil?
      return false if cc_size < min_size
      return false if cc_size > max_size
      return true
    end

  end

  class FilterStatus

    SKIP_STATUSES = [ EVENT_DEPOSITED,
                      EVENT_DEPOSIT_SKIPPED,
                      EVENT_UPLOAD_SKIPPED,
                      EVENT_EXPORT_FAILED,
                      EVENT_VERIFIED,
                      EVENT_VERIFYING ]

    attr_accessor :skip_statuses
    attr_accessor :debug_verbose

    def initialize( skip_statuses: nil )
      @skip_statuses = skip_statuses
      @skip_statuses ||= SKIP_STATUSES
      @skip_statuses = Array( @skip_statuses )
    end

    def include?( work: )
      status = Status.for_id( noid: work.id )
      return true if status.blank?
      status = status[0]
      return false if @skip_statuses.include? status.event
      return true
    end

  end

  class AptrustFilterWork

    FILTER_IN = FilterIn.new
    DEFAULT_FILTER_SIZE = FilterSize.new( min_size: 1, max_size: 100_000_000_000 )
    DEFAULT_FILTER_STATUS = FilterStatus.new

    attr_accessor :debug_verbose
    attr_accessor :filter_by_date
    attr_accessor :filter_by_size
    attr_accessor :filter_by_status

    def initialize( filter_by_date: nil, filter_by_size: nil, filter_by_status: nil )
      @filter_by_date = filter_by_date
      @filter_by_date ||= FILTER_IN
      @filter_by_size = filter_by_size
      @filter_by_size ||= DEFAULT_FILTER_SIZE
      @filter_by_status = filter_by_status
      @filter_by_status ||= DEFAULT_FILTER_STATUS
    end

    def debug_verbose=(flag)
      @debug_verbose = flag
      @filter_by_date.debug_verbose = flag if @filter_by_date.respond_to? :debug_verbose=
      @filter_by_size.debug_verbose = flag if @filter_by_size.respond_to? :debug_verbose=
      @filter_by_status.debug_verbose = flag if @filter_by_status.respond_to? :debug_verbose=
    end

    def set_filter_by_date( begin_date:, end_date: )
      @filter_by_date = FilterDate.new( begin_date: begin_date, end_date: end_date )
    end

    def set_filter_by_size( min_size: 1, max_size: )
      @filter_by_size = FilterSize.new( min_size: min_size, max_size: max_size )
    end

    def set_filter_by_status( skip_statuses: nil )
      @filter_by_status = FilterStatus.new( skip_statuses: skip_statuses )
    end

    def include?( work: )
      return false unless @filter_by_date.include? work: work
      return false unless @filter_by_size.include? work: work
      return false unless @filter_by_status.include? work: work
      return true
    end

  end

end
