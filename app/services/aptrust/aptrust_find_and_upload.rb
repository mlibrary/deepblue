# frozen_string_literal: true

require_relative './aptrust'

class Aptrust::AptrustFindAndUpload

  mattr_accessor :aptrust_find_and_upload_debug_verbose, default: false

  mattr_accessor :test_mode, default: true

  FILTER_DEFAULT = ::Aptrust::AptrustFilterWork.new unless const_defined? :FILTER_DEFAULT

  attr_accessor :aptrust_config
  attr_accessor :cleanup_after_deposit
  attr_accessor :cleanup_bag
  attr_accessor :cleanup_bag_data
  attr_accessor :clear_status
  attr_accessor :debug_assume_upload_succeeds
  attr_accessor :debug_verbose
  attr_accessor :export_file_sets
  attr_accessor :export_file_sets_filter_date
  attr_accessor :export_file_sets_filter_event
  attr_accessor :filter
  attr_accessor :max_upload_jobs
  attr_accessor :max_uploads
  attr_accessor :msg_handler
  attr_accessor :multibag_parts_included
  attr_accessor :track_status
  attr_accessor :upload_count

  def initialize( cleanup_after_deposit:         ::Aptrust::AptrustUploader.cleanup_after_deposit,
                  cleanup_bag:                   ::Aptrust::AptrustUploader.cleanup_bag,
                  cleanup_bag_data:              ::Aptrust::AptrustUploader.cleanup_bag_data,
                  clear_status:                  ::Aptrust::AptrustUploader.clear_status,
                  debug_assume_upload_succeeds:  false,
                  export_file_sets:              true,
                  export_file_sets_filter_date:  nil,
                  export_file_sets_filter_event: nil,
                  filter:                        nil,
                  max_upload_jobs:               1,
                  max_uploads:                   -1,
                  msg_handler:                   nil,
                  multibag_parts_included:       [],
                  track_status:                  true,
                  debug_verbose:                 aptrust_find_and_upload_debug_verbose )

    @debug_verbose = debug_verbose
    @debug_verbose ||= aptrust_find_and_upload_debug_verbose
    @msg_handler = msg_handler
    @msg_handler ||= ::Deepblue::MessageHandlerNull.new

    @cleanup_after_deposit         = cleanup_after_deposit
    @cleanup_bag                   = cleanup_bag
    @cleanup_bag_data              = cleanup_bag_data
    @clear_status                  = clear_status
    @debug_assume_upload_succeeds  = debug_assume_upload_succeeds
    @export_file_sets              = export_file_sets
    @export_file_sets_filter_date  = export_file_sets_filter_date
    @export_file_sets_filter_event = export_file_sets_filter_event
    @filter                        = filter
    @filter                       ||= FILTER_DEFAULT
    # @filter.debug_verbose = true if @filter.respond_to? :debug_verbose=

    @max_upload_jobs         = max_upload_jobs
    @max_uploads             = max_uploads
    @multibag_parts_included = multibag_parts_included
    @track_status            = track_status
    @upload_count            = 0

    @aptrust_config = ::Aptrust::AptrustConfig.new

    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "cleanup_after_deposit=#{cleanup_after_deposit}",
                             "cleanup_bag=#{cleanup_bag}",
                             "cleanup_bag_data=#{cleanup_bag_data}",
                             "clear_status=#{clear_status}",
                             "debug_assume_upload_succeeds=#{debug_assume_upload_succeeds}",
                             "export_file_sets=#{export_file_sets}",
                             "export_file_sets_filter_date=#{export_file_sets_filter_date}",
                             "export_file_sets_filter_event=#{export_file_sets_filter_event}",
                             "filter=#{filter}",
                             "max_upload_jobs=#{max_upload_jobs}",
                             "max_uploads=#{max_uploads}",
                             "multibag_parts_included=#{multibag_parts_included}",
                             "track_status=#{track_status}",
                             # "@aptrust_config.pretty_inspect=#{@aptrust_config.pretty_inspect}",
                             "" ] if debug_verbose
  end

  def process( work: )
    # TODO: deal with incomplete uploads
    # status = ::Aptrust::Status.for_id( noid: work.id )
    # status = status[0] unless status.blank?

    # else start uplaod
    if 1 == max_upload_jobs
      uploader = ::Aptrust::AptrustUploaderForWork.new( aptrust_config:                aptrust_config,
                                                        cleanup_after_deposit:         cleanup_after_deposit,
                                                        cleanup_bag:                   cleanup_bag,
                                                        cleanup_bag_data:              cleanup_bag_data,
                                                        clear_status:                  clear_status,
                                                        export_file_sets:              export_file_sets,
                                                        export_file_sets_filter_date:  export_file_sets_filter_date,
                                                        export_file_sets_filter_event: export_file_sets_filter_event,
                                                        multibag_parts_included:       multibag_parts_included,
                                                        track_status:                  track_status,
                                                        work:                          work,
                                                        msg_handler:                   msg_handler,
                                                        debug_verbose:                 debug_verbose )
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               # "uploader.aptrust_config=#{uploader.aptrust_config}",
                               "uploader.bag_id_context=#{uploader.bag_id_context}",
                               "uploader.bag_id_local_repository=#{uploader.bag_id_local_repository}",
                               "uploader.bag_id_type=#{uploader.bag_id_type}",
                               "uploader.bag_id=#{uploader.bag_id}",
                               "" ] if debug_verbose
      uploader.debug_assume_upload_succeeds = debug_assume_upload_succeeds
      uploader.upload
      @upload_count += 1
    else
      # TODO launch and keep track of jobs;
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "TODO launch and keep track of jobs",
                               "" ] if debug_verbose
    end
  end

  def run
    begin
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "" ] if debug_verbose
    DataSet.all.each do |work|
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "max_uploads=#{max_uploads}",
                               "@upload_count=#{@upload_count}",
                               "" ] if debug_verbose
      return if -1 != max_uploads && @upload_count >= max_uploads
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "work.id=#{work.id}",
                               "@upload_count=#{@upload_count}",
                               # "work.tombstone.present?=#{work.tombstone.present?}",
                               # "work.published?=#{work.published?}",
                               "" ] if debug_verbose
      # next if work.tombstone.present?
      # next unless work.published?
      filter_rv = filter.include? work: work
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "filter_rv=#{filter_rv}",
                               "" ] if debug_verbose
      next unless filter_rv
      process work: work
    end
    rescue Exception => e
      Rails.logger.error "#{e.class} -- #{e.message} at #{e.backtrace[0]}"
      msg_handler.bold_error [ msg_handler.here,
                               "Aptrust::AptrustFindAndUpload.run #{e.class}: #{e.message} at #{e.backtrace[0]}",
                               "" ] + e.backtrace # error
      raise
    end
  end

end
