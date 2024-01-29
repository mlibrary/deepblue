# frozen_string_literal: true

require_relative './aptrust'

class Aptrust::AptrustFindAndVerify

  mattr_accessor :aptrust_find_and_verify_debug_verbose, default: false

  mattr_accessor :test_mode, default: true

  attr_accessor :debug_assume_verify_succeeds
  attr_accessor :debug_verbose
  attr_accessor :force_verification
  attr_accessor :max_verifies
  attr_accessor :msg_handler

  attr_accessor :verify_count

  attr_accessor :aptrust_config

  def initialize( debug_assume_verify_succeeds: false,
                  force_verification:           false,
                  max_verifies:                 -1,
                  msg_handler:                  nil,
                  debug_verbose:                aptrust_find_and_verify_debug_verbose )

    @debug_verbose = debug_verbose
    @debug_verbose ||= aptrust_find_and_verify_debug_verbose
    @msg_handler = msg_handler
    @msg_handler ||= ::Deepblue::MessageHandlerNull.new

    @debug_assume_verify_succeeds = debug_assume_verify_succeeds
    @force_verification = force_verification
    @max_verifies = max_verifies
    @verify_count = 0
    @aptrust_config = ::Aptrust::AptrustConfig.new

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "debug_assume_verify_succeeds=#{debug_assume_verify_succeeds}",
                                           "force_verification=#{force_verification}",
                                           "max_verifies=#{max_verifies}",
                                           # "@aptrust_config.pretty_inspect=#{@aptrust_config.pretty_inspect}",
                                           "" ] if debug_verbose
  end

  def identifier( status: )
    return aptrust_config.identifier( noid: status.noid, type: status.type )
  end

  def process( identifier:, noid:, status: )
    verifier = ::Aptrust::AptrustStatusService.new( aptrust_config: aptrust_config,
                                                    track_status: true,
                                                    msg_handler: msg_handler,
                                                    debug_assume_verify_succeeds: debug_assume_verify_succeeds,
                                                    debug_verbose: debug_verbose )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "identifier=#{identifier}",
                                           "noid=#{noid}",
                                           "" ] if debug_verbose
    if status.event == ::Aptrust::EVENT_DEPOSIT_SKIPPED || debug_assume_verify_succeeds
      verifier.object_id = noid
      verifier.track( status: ::Aptrust::EVENT_VERIFY_SKIPPED )
      rv = ::Aptrust::EVENT_VERIFY_SKIPPED
    else
      rv = verifier.ingest_status( identifier: identifier, noid: noid, force: force_verification )
    end
    @verify_count += 1
    return rv
  end

  def run
    begin
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if debug_verbose

      ::Aptrust::Status.all.each do |status|
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "max_verifies=#{max_verifies}",
                                                 "@verify_count=#{@verify_count}",
                                                 "" ] if debug_verbose
        return if -1 != max_verifies && @verify_count >= max_verifies
        next unless ::Aptrust::EVENTS_NEED_VERIFY.include? status.event
        noid = status.noid
        identifier = identifier( status: status )
        rv = process( identifier: identifier, noid: noid, status: status )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "rv=#{rv}",
                                               "" ] if debug_verbose
      end
    rescue Exception => e
      Rails.logger.error "#{e.class} -- #{e.message} at #{e.backtrace[0]}"
      ::Deepblue::LoggingHelper.bold_error [ ::Deepblue::LoggingHelper.here,
                                             "Aptrust::AptrustFindAndVerify.run #{e.class}: #{e.message} at #{e.backtrace[0]}",
                                             "" ] + e.backtrace # error
      raise
    end
  end

end
