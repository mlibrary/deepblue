# frozen_string_literal: true

require_relative './aptrust'

class Aptrust::AptrustUploadWork

  mattr_accessor :aptrust_upload_work_debug_verbose, default: false

  attr_accessor :clean_up_after_deposit
  attr_accessor :clear_status
  attr_accessor :debug_assume_upload_succeeds
  attr_accessor :debug_verbose
  attr_accessor :msg_handler
  attr_accessor :noid

  attr_accessor :aptrust_config

  def initialize( clean_up_after_deposit:       ::Aptrust::AptrustUploader::CLEAN_UP_AFTER_DEPOSIT,
                  clear_status:                 ::Aptrust::AptrustUploader::CLEAR_STATUS,
                  debug_assume_upload_succeeds: false,
                  noid:                         ,
                  msg_handler:                  nil,
                  debug_verbose:                aptrust_upload_work_debug_verbose )

    @debug_verbose = debug_verbose
    @debug_verbose ||= aptrust_upload_work_debug_verbose
    @msg_handler = msg_handler
    @msg_handler ||= ::Deepblue::MessageHandlerNull.new

    @noid = noid

    @clean_up_after_deposit = clean_up_after_deposit
    @clear_status = clear_status
    @debug_assume_upload_succeeds = debug_assume_upload_succeeds

    @aptrust_config = ::Aptrust::AptrustConfig.new

    msg_handler.bold_debug [ msg_handler.here,
                                           msg_handler.called_from,
                                           "noid=#{noid}",
                                           "clean_up_after_deposit=#{clean_up_after_deposit}",
                                           "clear_status=#{clear_status}",
                                           "debug_assume_upload_succeeds=#{debug_assume_upload_succeeds}",
                                           "" ] if debug_verbose
  end

  def process( work: )
    # TODO: deal with incomplete uploads
    # status = ::Aptrust::Status.for_id( noid: work.id )
    # status = status[0] unless status.blank?

    uploader = ::Aptrust::AptrustUploaderForWork.new( aptrust_config: aptrust_config,
                                                      work: work,
                                                      msg_handler: msg_handler )
    msg_handler.bold_debug [ msg_handler.here,
                                           msg_handler.called_from,
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
  end

  def run
    begin # until true for break
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "run",
                               "" ] if debug_verbose
      work = PersistHelper.find_or_nil noid
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "work&.id=#{work&.id}",
                               "" ] if debug_verbose
      break if work.blank?
      process work: work
    rescue Exception => e
      Rails.logger.error "#{e.class} -- #{e.message} at #{e.backtrace[0]}"
      msg_handler.bold_error [ msg_handler.here,
                                             "Aptrust::AptrustUploadWork.run #{e.class}: #{e.message} at #{e.backtrace[0]}",
                                             "" ] + e.backtrace # error
      raise
    end until true # for break
    msg_handler.bold_debug [ msg_handler.here,
                             msg_handler.called_from,
                             "run",
                             "" ] if debug_verbose
  end

end
