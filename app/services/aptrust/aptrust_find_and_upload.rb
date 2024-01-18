# frozen_string_literal: true

require_relative './aptrust'

class Aptrust::AptrustFindAndUpload

  mattr_accessor :aptrust_find_and_upload_debug_verbose, default: false

  mattr_accessor :test_mode, default: true

  FILTER_DEFAULT = Aptrust::AptrustFilterWork.new unless const_defined? :FILTER_DEFAULT

  attr_accessor :clean_up_after_deposit
  attr_accessor :clear_status
  attr_accessor :debug_assume_upload_succeeds
  attr_accessor :debug_verbose
  attr_accessor :filter
  attr_accessor :max_upload_jobs
  attr_accessor :max_uploads
  attr_accessor :msg_handler

  attr_accessor :upload_count

  def initialize( clean_up_after_deposit:       ::Aptrust::AptrustUploader::CLEAN_UP_AFTER_DEPOSIT,
                  clear_status:                 ::Aptrust::AptrustUploader::CLEAR_STATUS,
                  debug_assume_upload_succeeds: false,
                  filter:                       nil,
                  max_upload_jobs:              1,
                  max_uploads:                  -1,
                  msg_handler:                  nil,
                  debug_verbose:                aptrust_find_and_upload_debug_verbose )

    @debug_verbose = debug_verbose
    @debug_verbose ||= aptrust_find_and_upload_debug_verbose
    @msg_handler = msg_handler
    @msg_handler ||= ::Deepblue::MessageHandlerNull.new

    @clean_up_after_deposit = clean_up_after_deposit
    @clear_status = clear_status
    @debug_assume_upload_succeeds = debug_assume_upload_succeeds
    @filter = filter
    @filter ||= FILTER_DEFAULT
    # @filter.debug_verbose = true if @filter.respond_to? :debug_verbose=

    @max_upload_jobs = max_upload_jobs
    @max_uploads = max_uploads

    @upload_count = 0

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "clean_up_after_deposit=#{clean_up_after_deposit}",
                                           "clear_status=#{clear_status}",
                                           "debug_assume_upload_succeeds=#{debug_assume_upload_succeeds}",
                                           "filter=#{filter}",
                                           "max_upload_jobs=#{max_upload_jobs}",
                                           "max_uploads=#{max_uploads}",
                                           "" ] if debug_verbose
  end

  def process( work: )
    # TODO: deal with incomplete uploads
    # status = ::Aptrust::Status.for_id( noid: work.id )
    # status = status[0] unless status.blank?

    # else start uplaod
    if 1 == max_upload_jobs
      uploader = ::Aptrust::AptrustUploaderForWork.new( work: work, msg_handler: msg_handler )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             # "uploader.aptrust_config=#{uploader.aptrust_config}",
                                             "uploader.bag_id_context=#{uploader.bag_id_context}",
                                             "uploader.bag_id_local_repository=#{uploader.bag_id_local_repository}",
                                             "uploader.bag_id_type=#{uploader.bag_id_type}",
                                             "uploader.bag_id=#{uploader.bag_id}",
                                             "" ] if debug_verbose
      uploader.clean_up_after_deposit = clean_up_after_deposit
      uploader.clear_status = clear_status
      uploader.debug_assume_upload_succeeds = debug_assume_upload_succeeds
      uploader.upload
      @upload_count += 1
    else
      # TODO launch and keep track of jobs;
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "TODO launch and keep track of jobs",
                                             "" ] if debug_verbose
    end
  end

  def run
    begin
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if debug_verbose
    DataSet.all.each do |work|
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "max_uploads=#{max_uploads}",
                                             "@upload_count=#{@upload_count}",
                                             "" ] if debug_verbose
      return if -1 != max_uploads && @upload_count >= max_uploads
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "work.id=#{work.id}",
                                             "@upload_count=#{@upload_count}",
                                             # "work.tombstone.present?=#{work.tombstone.present?}",
                                             # "work.published?=#{work.published?}",
                                             "" ] if debug_verbose
      # next if work.tombstone.present?
      # next unless work.published?
      filter_rv = filter.include? work: work
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "filter_rv=#{filter_rv}",
                                             "" ] if debug_verbose
      next unless filter_rv
      process work: work
    end
    rescue Exception => e
      puts e
      puts e.backtrace
    end
  end

end
