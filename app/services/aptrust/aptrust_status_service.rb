# frozen_string_literal: true

require_relative './aptrust'

class Aptrust::AptrustStatusService

  DEFAULT_TRACK_STATUS = true

  mattr_accessor :aptrust_status_service_debug_verbose, default: false

  attr_accessor :aptrust_config
  attr_accessor :aptrust_upload_status
  attr_accessor :base
  attr_accessor :debug_assume_verify_succeeds
  attr_accessor :debug_verbose
  attr_accessor :object_id
  attr_accessor :options
  attr_accessor :track_status

  def initialize( msg_handler:         nil,

                  aptrust_config:      nil,
                  aptrust_config_file: nil, # ignored if aptrust_config is defined

                  track_status:        DEFAULT_TRACK_STATUS,

                  debug_assume_verify_succeeds: false,

                  debug_verbose:       aptrust_status_service_debug_verbose )

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if debug_verbose
    @debug_verbose = debug_verbose
    @debug_verbose ||= aptrust_status_service_debug_verbose
    @msg_handler = msg_handler
    @msg_handler ||= ::Aptrust::NULL_MSG_HANDLER

    @aptrust_config      = aptrust_config
    @aptrust_config_file = aptrust_config_file

    @debug_assume_verify_succeeds = debug_assume_verify_succeeds

    @track_status ||= DEFAULT_TRACK_STATUS

    if @aptrust_config.blank?
      @aptrust_config = if @aptrust_config_file.present?
                          ::Aptrust::AptrustConfig.new( filename: @aptrust_config_filename )
                        else
                          ::Aptrust::AptrustConfig.new
                        end
    end
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           # "@aptrust_config=#{@aptrust_config.pretty_inspect}",
                                           "" ] if debug_verbose

  end

  def aptrust_upload_status
    @aptrust_uploader_status ||= ::Aptrust::AptrustUploaderStatus.new( id: @object_id )
  end

  def base
    @base ||= aptrust_config.aptrust_api_url
  end

  def ingest_status( identifier:, noid:, force: false )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "identifier=#{identifier}",
                                           "noid=#{noid}",
                                           "force=#{force}",
                                           "track_status=#{track_status}",
                                           "" ] if debug_verbose
    @object_id = noid

    begin # until true for break
      status = aptrust_upload_status.status
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "status=#{status}",
                                             "" ] if debug_verbose
      if !force && !Aptrust::EVENTS_NEED_VERIFY.include?( status )
        rv = status
        break
      end
      object_identifier = "object_identifier=#{aptrust_config.repository}\/#{identifier}"
      get_arg = "items?#{object_identifier}&action=Ingest"
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "get_arg=#{get_arg}",
                                             "" ] if debug_verbose
      track( status: ::Aptrust::EVENT_VERIFYING, note: "object_identifier=#{aptrust_config.repository}\/#{identifier}" )
      response = connection.get( get_arg )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "response=#{response}",
                                             "" ] if debug_verbose
      unless response.success?
        rv = 'http_error'
        track( status: ::Aptrust::EVENT_VERIFY_FAILED, note: "#{rv} - #{object_identifier}" )
        break
      end
      results = response.body['results']
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "results=#{results}",
                                             "" ] if debug_verbose
      if results.blank?
        rv = 'not_found'
        track( status: ::Aptrust::EVENT_VERIFY_FAILED, note: "#{rv} - #{object_identifier}" )
        break
      end
      item = results.first
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "item=#{item}",
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
      ::Deepblue::LoggingHelper.bold_error [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "Aptrust::AptrustStatusService.ingest_status(#{identifier}) #{e}",
                                             "" ]
      rv = 'standard_error'
      track( status: ::Aptrust::EVENT_VERIFY_FAILED, note: "#{rv} - #{object_identifier}" )
    end until true
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "rv=#{rv}",
                                           "" ] if debug_verbose
    return rv
  end

  def track( status:, note: nil )
    aptrust_upload_status.track( status: status, note: note ) if track_status
  end

  private

    def connection
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "base=#{base}",
                                             "aptrust_config.aptrust_api_user=#{aptrust_config.aptrust_api_user}",
                                             "aptrust_config.aptrust_api_key=#{aptrust_config.aptrust_api_key}",
                                             "" ] if debug_verbose
      @connection ||= Faraday.new( base ) do |conn|
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
    end

end
