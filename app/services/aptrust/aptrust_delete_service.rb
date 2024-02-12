# frozen_string_literal: true

require_relative './aptrust'

class Aptrust::AptrustDeleteService < Aptrust::AbstractAptrustService

  # see: https://raw.githubusercontent.com/APTrust/registry/master/member_api_v3.yml

  mattr_accessor :aptrust_delete_service_debug_verbose, default: true

  attr_accessor :debug_assume_delete_succeeds
  attr_accessor :noid

  def initialize( msg_handler:         nil,
                  aptrust_config:      nil,
                  aptrust_config_file: nil, # ignored if aptrust_config is defined
                  track_status:        true,

                  debug_assume_delete_succeeds: false,

                  debug_verbose:       aptrust_delete_service_debug_verbose )

    super( msg_handler:         msg_handler,
           aptrust_config:      aptrust_config,
           aptrust_config_file: aptrust_config_file,
           track_status:        track_status,
           debug_verbose:       debug_verbose )

    @debug_assume_delete_succeeds = debug_assume_delete_succeeds
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "debug_assume_delete_succeeds=#{@debug_assume_delete_succeeds}",
                             "" ] if debug_verbose
  end

  def delete( identifier:, noid: )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "identifier=#{identifier}",
                             "noid=#{noid}",
                             "track_status=#{track_status}",
                             "" ] if debug_verbose
    @noid = noid

    begin # until true for break
      status = aptrust_upload_status.status
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "@aptrust_uploader_status.object_id=#{@aptrust_uploader_status.object_id}",
                               "" ] if debug_verbose
      object_identifier = "object_identifier=#{aptrust_config.repository}\/#{identifier}"
      get_arg = "items?#{object_identifier}&action=Delete"
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "get_arg=#{get_arg}",
                               "" ] if debug_verbose
      track( status: ::Aptrust::EVENT_DELETING, note: "object_identifier=#{aptrust_config.repository}\/#{identifier}" )
      response = connection.get( get_arg )
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "response.success?=#{response.success?}",
                               # "response.pretty_inspect=#{response.pretty_inspect}",
                               "" ] if debug_verbose
      unless response.success?
        rv = 'http_error'
        track( status: ::Aptrust::EVENT_DELETE_FAILED, note: "#{rv} - #{object_identifier}" )
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
        track( status: ::Aptrust::EVENT_DELETE_FAILED, note: "#{rv} - #{object_identifier}" )
        break
      end
      item = results.first
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "item.pretty_inspect=#{item.pretty_inspect}",
                               "" ] if debug_verbose
      track( status: ::Aptrust::EVENT_DELETE_PENDING, note: "#{object_identifier}" )
    rescue StandardError => e
      msg_handler.bold_error [ msg_handler.here, msg_handler.called_from,
                               "Aptrust::AptrustDeleteService.ingest_status(#{identifier}) #{e}",
                               "" ] # + e.backtrace # [0..40]
      rv = 'standard_error'
      track( status: ::Aptrust::EVENT_DELETE_FAILED, note: "#{rv} - #{object_identifier}" )
    end until true
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "rv=#{rv}",
                             "" ] if debug_verbose
    return rv
  end

end
