# frozen_string_literal: true

require_relative './aptrust'

class Aptrust::AptrustStatusService < Aptrust::AbstractAptrustService

  # see: https://raw.githubusercontent.com/APTrust/registry/master/member_api_v3.yml

  mattr_accessor :aptrust_status_service_debug_verbose, default: false

  attr_accessor :debug_assume_verify_succeeds
  attr_accessor :force
  attr_accessor :noid
  attr_accessor :reverify_failed

  def initialize( msg_handler:         nil,
                  aptrust_config:      nil,
                  aptrust_config_file: nil, # ignored if aptrust_config is defined
                  track_status:        true,
                  test_mode:           false,

                  debug_assume_verify_succeeds: false,
                  force:               false,
                  reverify_failed:     false,

                  debug_verbose:       aptrust_status_service_debug_verbose )

    super( msg_handler:         msg_handler,
           aptrust_config:      aptrust_config,
           aptrust_config_file: aptrust_config_file,
           track_status:        track_status,
           test_mode:           test_mode,
           debug_verbose:       debug_verbose )

    @debug_assume_verify_succeeds = debug_assume_verify_succeeds
    @force = force
    @reverify_failed = reverify_failed
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "debug_assume_verify_succeeds=#{@debug_assume_verify_succeeds}",
                             "force=#{@force}",
                             "reverify_failed=#{@reverify_failed}",
                             "" ] if debug_verbose
  end

  def ingest_result_to_verification( current_status:, results: )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "current_status=#{current_status}",
                             "results=#{results}",
                             "" ] if debug_verbose
    rv = ::Aptrust::EVENT_VERIFY_PENDING
    begin # until true for break
      if results.blank?
        break if ::Aptrust::EVENTS_PROCESSING.include?( current_status )
        break if ::Aptrust::EVENTS_NEED_VERIFY.include?( current_status )
      end
      results = results.first if results.is_a? Array
      status = results['status']
      rv = ::Aptrust::EVENT_VERIFY_FAILED
      break if /failed/i.match? status
      break if /cancelled/i.match? status
      stage = results['stage']
      if /success/i.match?( status ) && /cleanup/i.match?( stage )
        rv = ::Aptrust::EVENT_VERIFIED
        break
      end
      rv = ::Aptrust::EVENT_VERIFY_PENDING
    end until true # for break
    return rv
  end

  def ingest_status2( identifier:, noid: )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "identifier=#{identifier}",
                             "noid=#{noid}",
                             "force=#{force}",
                             "reverify_failed=#{reverify_failed}",
                             "track_status=#{track_status}",
                             "" ] if debug_verbose
    @noid = noid

    begin # until true for break
      status = aptrust_upload_status.status
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "@aptrust_uploader_status.object_id=#{@aptrust_uploader_status.object_id}",
                               "needs_verification?( status: #{status} )=#{needs_verification?( status: status )}",
                               "" ] if debug_verbose
      unless needs_verification?( status: status )
        msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                                 "skip because it does not need verification",
                                 "" ] if debug_verbose
        rv = status
        break
      end
      object_identifier = "object_identifier=#{aptrust_config.repository}\/#{identifier}"
      get_arg = "items?#{object_identifier}&action=Ingest"
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "get_arg=#{get_arg}",
                               "" ] if debug_verbose
      track( status: ::Aptrust::EVENT_VERIFYING, note: "object_identifier=#{aptrust_config.repository}\/#{identifier}" )
      response = connection.get( get_arg )
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "response.success?=#{response.success?}",
                               # "response.pretty_inspect=#{response.pretty_inspect}",
                               "" ] if debug_verbose
      unless response.success?
        rv = 'http_error'
        # track( status: ::Aptrust::EVENT_VERIFY_FAILED, note: "#{rv} - #{object_identifier}" )
        break
      end
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               # "response.pretty_inspect=#{response.pretty_inspect}",
                               "response.success?=#{response.success?}",
                               "response.body.pretty_inspect=#{response.body.pretty_inspect}",
                               "" ] if debug_verbose
      results = response.body['results']
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "results=#{results}",
                               "" ] if debug_verbose
      if results.blank?
        rv = 'not_found'
        track( status: ::Aptrust::EVENT_VERIFY_FAILED, note: "#{rv} - #{object_identifier}" )
        break
      end
      item = results.first
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "item.pretty_inspect=#{item.pretty_inspect}",
                               "" ] if debug_verbose
      if /failed/i.match?(item['status']) || /cancelled/i.match?(item['status'])
        rv =  'failed'
        track( status: ::Aptrust::EVENT_VERIFY_FAILED, note: "#{object_identifier}" )
        break
      end
      if /cleanup/i.match?(item['stage']) && /success/i.match?(item['status'])
        rv = 'success'
        track( status: ::Aptrust::EVENT_VERIFIED, note: "#{object_identifier}" )
        break
      end
      rv = 'pending'
      track( status: ::Aptrust::EVENT_VERIFY_PENDING, note: "#{object_identifier}" )
    rescue StandardError => e
      msg_handler.bold_error [ msg_handler.here, msg_handler.called_from,
                               "Aptrust::AptrustStatusService.ingest_status2(#{identifier}) #{e}",
                               "" ] # + e.backtrace # [0..40]
      rv = 'standard_error'
      track( status: ::Aptrust::EVENT_VERIFY_FAILED, note: "#{rv} - #{object_identifier}" )
    end until true # for break
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "rv=#{rv}",
                             "" ] if debug_verbose
    return rv
  end

  def ingest_status( identifier:, noid: )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "identifier=#{identifier}",
                             "noid=#{noid}",
                             "force=#{force}",
                             "reverify_failed=#{reverify_failed}",
                             "track_status=#{track_status}",
                             "test_mode=#{test_mode}",
                             "" ] if debug_verbose
    msg_handler.msg_debug [ "identifier=#{identifier}",
                             "noid=#{noid}",
                             "force=#{force}",
                             "reverify_failed=#{reverify_failed}",
                             "track_status=#{track_status}",
                            "test_mode=#{test_mode}" ] if debug_verbose
    return ::Aptrust::EVENT_VERIFY_SKIPPED if test_mode
    @noid = noid
    @aptrust_upload_status = nil

    begin # until true for break
      status = aptrust_upload_status.status
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "@aptrust_uploader_status.object_id=#{@aptrust_uploader_status.object_id}",
                               "needs_verification?( status: #{status} )=#{needs_verification?( status: status )}",
                               "" ] if debug_verbose
      msg_handler.msg_debug "@aptrust_uploader_status.object_id=#{@aptrust_uploader_status.object_id}" if debug_verbose
      msg_handler.msg_debug "needs_verification?( status: #{status} )=#{needs_verification?( status: status )}" if debug_verbose
      unless needs_verification?( status: status )
        msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                                 "skip because it does not need verification",
                                 "" ] if debug_verbose
        msg_handler.msg_debug "skip because it does not need verification" if debug_verbose
        rv = status
        break
      end
      object_identifier = "object_identifier=#{aptrust_config.repository}\/#{identifier}"
      get_arg = "items?#{object_identifier}&action=Ingest"
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "get_arg=#{get_arg}",
                               "" ] if debug_verbose
      msg_handler.msg_debug "get_arg=#{get_arg}" if debug_verbose
      # track( status: ::Aptrust::EVENT_VERIFYING, note: "object_identifier=#{aptrust_config.repository}\/#{identifier}" )
      response = connection.get( get_arg )
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "response.success?=#{response.success?}",
                               # "response.pretty_inspect=#{response.pretty_inspect}",
                               "" ] if debug_verbose
      msg_handler.msg_debug "response.success?=#{response.success?}" if debug_verbose
      unless response.success?
        rv = 'http_error'
        # track( status: ::Aptrust::EVENT_VERIFY_FAILED, note: "#{rv} - #{object_identifier}" )
        break
      end
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               # "response.pretty_inspect=#{response.pretty_inspect}",
                               "response.success?=#{response.success?}",
                               "response.body.pretty_inspect=#{response.body.pretty_inspect}",
                               "" ] if debug_verbose
      msg_handler.msg_debug "response.success?=#{response.success?}" if debug_verbose
      rv = ingest_result_to_verification( current_status: status, results: response.body['results'] )
      break if rv == ::Aptrust::EVENT_VERIFY_FAILED
      msg_handler.msg_debug "setting #{noid} status to #{rv}"
      track( status: rv )
    rescue StandardError => e
      msg_handler.bold_error [ msg_handler.here, msg_handler.called_from,
                               "Aptrust::AptrustStatusService.ingest_status(#{identifier}) #{e}",
                               "" ] # + e.backtrace # [0..40]
      msg_handler.msg_error "Aptrust::AptrustStatusService.ingest_status(#{identifier}) #{e}"
      rv = 'standard_error'
      track( status: ::Aptrust::EVENT_VERIFY_FAILED, note: "#{rv} - #{object_identifier}" )
    end until true # for break
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "rv=#{rv}",
                             "" ] if debug_verbose
    return rv
  end

  def ingest_status_body( identifier: )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "identifier=#{identifier}",
                             "" ] if debug_verbose
    begin # until true for break
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "force=#{force}",
                               "reverify_failed=#{reverify_failed}",
                               "" ] if debug_verbose
      object_identifier = "object_identifier=#{aptrust_config.repository}\/#{identifier}"
      get_arg = "items?#{object_identifier}&action=Ingest"
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "get_arg=#{get_arg}",
                               "" ] if debug_verbose
      rv = get_response_body( get_arg: get_arg )
      success = rv[0]
      http_status = rv[1]
      body = rv[2]
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "success=#{success}",
                               "http_status=#{http_status}",
                               "body.pretty_inspect=#{body.pretty_inspect}",
                               "" ] if debug_verbose
      unless success
        rv = 'http_error'
        break
      end
      rv = body
    rescue StandardError => e
      msg_handler.bold_error [ msg_handler.here, msg_handler.called_from,
                               "Aptrust::AptrustStatusService.ingest_status(#{identifier}) #{e}",
                               "" ] # + e.backtrace # [0..40]
      rv = 'standard_error'
    end until true
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "rv=#{rv}",
                             "" ] if debug_verbose
    return rv
  end

  def needs_verification?( status: )
    return true if force
    return true if reverify_failed && ::Aptrust::EVENTS_FAILED.include?( status )
    return true if ::Aptrust::EVENTS_NEED_VERIFY.include?( status )
    return false
  end

end
