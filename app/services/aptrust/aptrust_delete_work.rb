# frozen_string_literal: true

require_relative './aptrust'

class Aptrust::AptrustDeleteWork < Aptrust::AbstractAptrustService

  mattr_accessor :aptrust_delete_work_debug_verbose, default: false

  attr_accessor :debug_assume_delete_succeeds
  attr_accessor :noid

  def initialize( msg_handler:         nil,
                  aptrust_config:      nil,
                  aptrust_config_file: nil, # ignored if aptrust_config is defined
                  debug_assume_delete_succeeds: false,
                  noid:                ,
                  debug_verbose:       aptrust_delete_work_debug_verbose )

    super( msg_handler:         msg_handler,
           aptrust_config:      aptrust_config,
           aptrust_config_file: aptrust_config_file,
           debug_verbose:       debug_verbose )

    @noid = noid

    @debug_assume_delete_succeeds = debug_assume_delete_succeeds

    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "noid=#{noid}",
                             "debug_assume_delete_succeeds=#{debug_assume_delete_succeeds}",
                             "" ] if debug_verbose
  end

  def process( identifier:, noid:, status: )
    verifier = ::Aptrust::AptrustStatusService.new( aptrust_config: aptrust_config,
                                                    force: force_verification,
                                                    track_status: true,
                                                    msg_handler: msg_handler,
                                                    debug_assume_delete_succeeds: debug_assume_delete_succeeds,
                                                    debug_verbose: debug_verbose )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "identifier=#{identifier}",
                             "noid=#{noid}",
                             "status.event=#{status.event}",
                             "" ] if debug_verbose
    if status.event == ::Aptrust::EVENT_DEPOSIT_SKIPPED || debug_assume_delete_succeeds
      track( status: ::Aptrust::EVENT_VERIFY_SKIPPED )
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
    begin # until true for break
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "run",
                               "" ] if debug_verbose
      status = ::Aptrust::Status.where( noid: noid )
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "status.size=#{status.size}",
                               "" ] if debug_verbose
      break if status.blank?
      status = status.first
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "status.noid=#{status.noid}",
                               "status.event=#{status.event}",
                               "" ] if debug_verbose
      break unless needs_verification?( status: status.event )
      identifier = identifier( status: status )
      process( identifier: identifier, noid: status.noid, status: status )
    rescue Exception => e
      Rails.logger.error "#{e.class} -- #{e.message} at #{e.backtrace[0]}"
      msg_handler.bold_error [ msg_handler.here, msg_handler.called_from,
                               "Aptrust::AptrustDeleteWork.run #{e.class}: #{e.message} at #{e.backtrace[0]}",
                               "" ] + e.backtrace # error
      raise
    end until true # for break
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "run",
                             "" ] if debug_verbose
  end

end
