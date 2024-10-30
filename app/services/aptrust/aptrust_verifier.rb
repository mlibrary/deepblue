# frozen_string_literal: true

require_relative './aptrust'

class Aptrust::AptrustVerifier < Aptrust::AbstractAptrustService

  mattr_accessor :aptrust_verifier_debug_verbose, default: false

  attr_accessor :debug_assume_verify_succeeds
  attr_accessor :force_verification
  attr_accessor :noid
  attr_accessor :reverify_failed

  def initialize( msg_handler:         nil,
                  aptrust_config:      nil,
                  aptrust_config_file: nil, # ignored if aptrust_config is defined
                  debug_assume_verify_succeeds: false,
                  force_verification:           false,
                  reverify_failed:              false,
                  noid:                         ,
                  track_status:                 true,
                  test_mode:                    false,
                  debug_verbose:                aptrust_verifier_debug_verbose )

    super( msg_handler:         msg_handler,
           aptrust_config:      aptrust_config,
           aptrust_config_file: aptrust_config_file,
           track_status:        track_status,
           test_mode:           test_mode,
           debug_verbose:       debug_verbose )

    @noid = noid

    @debug_assume_verify_succeeds = debug_assume_verify_succeeds
    @force_verification = force_verification
    @reverify_failed = reverify_failed

    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "noid=#{noid}",
                             "debug_assume_verify_succeeds=#{debug_assume_verify_succeeds}",
                             "force_verification=#{force_verification}",
                             "reverify_failed=#{reverify_failed}",
                             "" ] if debug_verbose
  end

  def needs_verification?( status: )
    return true if force_verification
    return true if reverify_failed && ::Aptrust::EVENTS_FAILED.include?( status )
    return true if ::Aptrust::EVENTS_NEED_VERIFY.include?( status )
    return false
  end

  def process( work: )
    status = ::Aptrust::Status.where( noid: work.id )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "status.size=#{status.size}",
                             "" ] if debug_verbose
    return if status.blank?
    identifier = identifier( status: status )
    verifier = ::Aptrust::AptrustStatusService.new( aptrust_config: aptrust_config,
                                                    force: force_verification,
                                                    reverify_failed: reverify_failed,
                                                    track_status: true,
                                                    test_mode: test_mode,
                                                    msg_handler: msg_handler,
                                                    debug_assume_verify_succeeds: debug_assume_verify_succeeds,
                                                    debug_verbose: debug_verbose )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "identifier=#{identifier}",
                             "noid=#{noid}",
                             "status.event=#{status.event}",
                             "" ] if debug_verbose
    if status.event == ::Aptrust::EVENT_DEPOSIT_SKIPPED || debug_assume_verify_succeeds
      track( status: ::Aptrust::EVENT_VERIFY_SKIPPED ) unless test_mode
      rv = ::Aptrust::EVENT_VERIFY_SKIPPED
    else
      rv = verifier.ingest_status( identifier: identifier, noid: noid )
    end
    @verify_count += 1
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "identifier=#{identifier}",
                             "noid=#{noid}",
                             "rv=#{rv}",
                             "" ] if debug_verbose
    return rv
  end

  def run
    begin
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "" ] if debug_verbose
      work = DataSet.find noid
      process work: work
    rescue Exception => e
      Rails.logger.error "#{e.class} -- #{e.message} at #{e.backtrace[0]}"
      msg_handler.bold_error [ msg_handler.here, msg_handler.called_from,
                               "Aptrust::AptrustVerifier.run #{e.class}: #{e.message} at #{e.backtrace[0]}",
                               "" ] + e.backtrace # error
      raise
    end
  end

end
