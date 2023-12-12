# frozen_string_literal: true

require_relative './aptrust'

module Aptrust

  class AptrustFindAndUpload

    mattr_accessor :aptrust_find_and_upload_debug_verbose, default: false

    mattr_accessor :test_mode, default: true

    FILTER_DEFAULT = AptrustFilterWork.new

    attr_accessor :debug_verbose
    attr_accessor :filter
    attr_accessor :max_upload_jobs
    attr_accessor :msg_handler

    def initialize( filter: nil, msg_handler: nil, debug_verbose: aptrust_find_and_upload_debug_verbose  )
      @debug_verbose = debug_verbose
      @debug_verbose ||= aptrust_find_and_upload_debug_verbose
      @msg_handler = msg_handler
      @msg_handler ||= ::Deepblue::MessageHandlerNull.new
      @filter = filter
      @filter ||= FILTER_DEFAULT
      @filter.debug_verbose = true if @filter.respond_to? :debug_verbose=
      @max_upload_jobs = 1
    end

    def process( work: )
      # TODO: deal with incomplete uploads
      # status = Status.for_id( noid: work.id )
      # status = status[0] unless status.blank?

      # else start uplaod
      if 1 == max_upload_jobs
        uploader = AptrustUploaderForWork.new( work: work, msg_handler: msg_handler )
        # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
        #                                        ::Deepblue::LoggingHelper.called_from,
        #                                        "uploader.aptrust_config=#{uploader.aptrust_config}",
        #                                        "uploader.bag_id_context=#{uploader.bag_id_context}",
        #                                        "uploader.bag_id_repository=#{uploader.bag_id_repository}",
        #                                        "uploader.bag_id_type=#{uploader.bag_id_type}",
        #                                        "uploader.bag_id=#{uploader.bag_id}",
        #                                        "" ] if debug_verbose
        uploader.upload
      else
        # TODO launch and keep track of jobs;
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
                                               "work.id=#{work.id}",
                                               "" ] if debug_verbose
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

end
