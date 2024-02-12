# frozen_string_literal: true

require_relative './aptrust'

class Aptrust::AbstractAptrustService

  # see: https://raw.githubusercontent.com/APTrust/registry/master/member_api_v3.yml

  DEFAULT_TRACK_STATUS = false unless const_defined? :DEFAULT_TRACK_STATUS

  mattr_accessor :abstract_aptrust_service_debug_verbose, default: true

  attr_accessor :aptrust_config
  attr_accessor :aptrust_upload_status
  attr_accessor :base_url
  attr_accessor :debug_verbose
  attr_accessor :msg_handler
  attr_accessor :options
  attr_accessor :track_status

  def initialize( msg_handler:         nil,
                  aptrust_config:      nil,
                  aptrust_config_file: nil, # ignored if aptrust_config is defined
                  track_status:        DEFAULT_TRACK_STATUS,

                  debug_verbose:       abstract_aptrust_service_debug_verbose )

    @debug_verbose = debug_verbose
    @debug_verbose ||= abstract_aptrust_service_debug_verbose
    @msg_handler = msg_handler
    @msg_handler ||= ::Aptrust::NULL_MSG_HANDLER

    @aptrust_config      = aptrust_config
    @aptrust_config_file = aptrust_config_file

    @track_status ||= DEFAULT_TRACK_STATUS

    if @aptrust_config.blank?
      @aptrust_config = if @aptrust_config_file.present?
                          ::Aptrust::AptrustConfig.new( filename: @aptrust_config_filename )
                        else
                          ::Aptrust::AptrustConfig.new
                        end
    end
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "track_status=#{@track_status}",
                             "" ] if debug_verbose
  end

  def aptrust_upload_status
    @aptrust_upload_status ||= ::Aptrust::AptrustUploaderStatus.new( id: @noid )
  end

  def base_url
    @base_url ||= aptrust_config.aptrust_api_url
  end

  def get_response_body( get_arg: )
    begin # until true for break
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "get_arg=#{get_arg}",
                               "" ] if debug_verbose
      response = connection.get( get_arg )
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "response.success?=#{response.success?}",
                               "response.status=#{response.status}",
                               # "response.body=#{response.body.pretty_inspect}",
                               # "response.pretty_inspect=#{response.pretty_inspect}",
                               "" ] if debug_verbose
      rv = [ response.success?, response.status, response.body ]
    rescue StandardError => e
      msg_handler.bold_error [ msg_handler.here, msg_handler.called_from,
                               "Aptrust::AbstractAptrustService.get_response_body(get_arg:#{get_arg}) #{e}",
                               "" ] # + e.backtrace # [0..40]
      rv = [ false, nil, nil ]
    end until true
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "rv=#{rv}",
                             "" ] if debug_verbose
    return rv
  end

  def identifier( status: )
    return aptrust_config.identifier( noid: status.noid, type: "#{status.type}." )
  end

  def track( status:, note: nil )
    aptrust_upload_status.track( status: status, note: note ) if track_status
  end

  protected

  def connection
    @connection ||= connection_init
  end

  def connection_init
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "base_url=#{base_url}",
                             # "aptrust_config.aptrust_api_user=#{aptrust_config.aptrust_api_user}",
                             # "aptrust_config.aptrust_api_key=#{aptrust_config.aptrust_api_key}",
                             "" ] if debug_verbose
    rv = Faraday.new( base_url ) do |conn|
      conn.headers = {
        accept: "application/json",
        content_type: "application/json",
        "X-Pharos-API-User" => aptrust_config.aptrust_api_user,
        "X-Pharos-API-Key" => aptrust_config.aptrust_api_key
      }
      conn.request :json
      conn.response :json, content_type: /\bjson$/
      conn.options[:open_timeout] = 60 # seconds, 1 minute, opening a connection
      conn.options[:timeout] = 60 # seconds, 1 minute, waiting for response
      conn.adapter Faraday.default_adapter
    end
    return rv
  end

end
