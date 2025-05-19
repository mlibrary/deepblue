# frozen_string_literal: true

require_relative './aptrust'

class DataDen::FilterIn
  def include?( file_set: )
    return true
  end
end

class DataDen::FilterDate

  attr_accessor :debug_verbose
  attr_accessor :filter

  def initialize( begin_date:, end_date: )
    if begin_date.present? || end_date.present?
      @filter = ::Deepblue::FindCurationConcernFilterDate.new( begin_date: begin_date, end_date: end_date )
    else
      @filter = nil
    end
  end

  def include?( file_set: )
    return true if @filter.nil?
    @filter.include? work.date_modified
  end

end

class DataDen::FilterSize

  attr_accessor :debug_verbose
  attr_accessor :max_size
  attr_accessor :min_size

  def initialize( min_size: 1, max_size: )
    @max_size = max_size
    @min_size = min_size
    @min_size = 1 if @min_size < 1
    @max_size = @min_size if @max_size < @min_size
  end

  def include?( file_set: )
    cc_size = file_set.file_size # is this correct
    return false if cc_size.nil?
    return false if cc_size < min_size
    return false if cc_size > max_size
    return true
  end

end

class DataDen::FilterStatus

  SKIP_STATUSES = [ ::DataDen::EVENT_DEPOSITED,
                    ::DataDen::EVENT_DEPOSIT_SKIPPED,
                    ::DataDen::EVENT_UPLOAD_SKIPPED,
                    ::DataDen::EVENT_EXPORT_FAILED,
                    ::DataDen::EVENT_VERIFIED,
                    ::DataDen::EVENT_VERIFY_FAILED,
                    ::DataDen::EVENT_VERIFYING ] unless const_defined? :SKIP_STATUSES

  attr_accessor :debug_verbose
  attr_accessor :skip_statuses

  def initialize( skip_statuses: nil )
    @skip_statuses = skip_statuses
    @skip_statuses ||= SKIP_STATUSES
    @skip_statuses = Array( @skip_statuses )
  end

  def include?( file_set: )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "file_set.id=#{file_set.id}",
                                           "" ] if debug_verbose
    status = ::DataDen::Status.for_id( noid: file_set.id )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "status=#{status}",
                                           "" ] if debug_verbose
    return true if status.blank?
    status = status[0]
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "status=#{status}",
                                           "" ] if debug_verbose
    rv = @skip_statuses.include? status.event
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "#{@skip_statuses}.include? #{status.event}=#{rv}",
                                           "" ] if debug_verbose
    return false if rv
    return true
  end

end

class DataDen::FilterFileSet

  FILTER_IN = ::DataDen::FilterIn.new
  DEFAULT_FILTER_SIZE = ::DataDen::FilterSize.new( min_size: 1, max_size: 100_000_000_000 )
  DEFAULT_FILTER_STATUS = ::DataDen::FilterStatus.new

  attr_accessor :debug_verbose
  attr_accessor :filter_by_date
  attr_accessor :filter_by_size
  attr_accessor :filter_by_status

  def initialize( filter_by_date: nil, filter_by_size: nil, filter_by_status: nil, debug_verbose: false )
    @debug_verbose = debug_verbose
    @filter_by_date = filter_by_date
    @filter_by_date ||= FILTER_IN
    @filter_by_size = filter_by_size
    @filter_by_size ||= DEFAULT_FILTER_SIZE
    @filter_by_status = filter_by_status
    @filter_by_status ||= DEFAULT_FILTER_STATUS
    @filter_by_date.debug_verbose = debug_verbose if @filter_by_date.respond_to? :debug_verbose=
    @filter_by_size.debug_verbose = debug_verbose if @filter_by_size.respond_to? :debug_verbose=
    @filter_by_status.debug_verbose = debug_verbose if @filter_by_status.respond_to? :debug_verbose=
  end

  def debug_verbose=( flag )
    @debug_verbose = flag
    @filter_by_date.debug_verbose = flag if @filter_by_date.respond_to? :debug_verbose=
    @filter_by_size.debug_verbose = flag if @filter_by_size.respond_to? :debug_verbose=
    @filter_by_status.debug_verbose = flag if @filter_by_status.respond_to? :debug_verbose=
  end

  def set_filter_by_date( begin_date:, end_date: )
    @filter_by_date = ::DataDen::FilterDate.new( begin_date: begin_date, end_date: end_date )
    @filter_by_date.debug_verbose = debug_verbose if @filter_by_date.respond_to? :debug_verbose=
  end

  def set_filter_by_size( min_size: 1, max_size: )
    @filter_by_size = ::DataDen::FilterSize.new( min_size: min_size, max_size: max_size )
    @filter_by_size.debug_verbose = debug_verbose if @filter_by_size.respond_to? :debug_verbose=
  end

  def set_filter_by_status( skip_statuses: nil )
    if skip_statuses.blank?
      @filter_by_status = FILTER_IN
    else
      @filter_by_status = ::DataDen::FilterStatus.new( skip_statuses: skip_statuses )
      @filter_by_status.debug_verbose = debug_verbose if @filter_by_status.respond_to? :debug_verbose=
    end
  end

  def include?( file_set: )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "file_set.id=#{file_set.id}",
                                           "" ] if debug_verbose

    return false unless include_by_date? file_set: work
    return false unless include_by_size? file_set: work
    return false unless include_by_status? file_set: work
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "include? including file_set.id=#{file_set.id}",
                                           "" ] if debug_verbose
    return true
  end

  def include_by_date?( file_set: )
    rv_include = @filter_by_date.include? file_set: work
    if !rv_include
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "include_by_date? #{rv_include} exclude file_set.id=#{file_set.id}",
                                             "" ] if debug_verbose
    end
    return rv_include
  end

  def include_by_size?( file_set: )
    rv_include = @filter_by_size.include? file_set: work
    if !rv_include
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "include_by_size? #{rv_include} exclude file_set.id=#{file_set.id}",
                                             "" ] if debug_verbose
    end
    return rv_include
  end

  def include_by_status?( file_set: )
    rv_include = @filter_by_status.include? file_set: work
    if !rv_include
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "",
                                             "include_by_status? #{rv_include} exclude file_set.id=#{file_set.id}",
                                             "" ] if debug_verbose
    end
    return rv_include
  end

end
