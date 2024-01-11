# frozen_string_literal: true

module Aptrust

  class AptrustStatusService

    mattr_accessor :aptrust_status_service_debug_verbose, default: true

    def ingest_status( identifier )
      # TODO: figure out what the identifier should really be
      get_arg = "items?object_identifier=#{aptrust_config.repository}\/#{identifier}&action=Ingest"
      response = connection.get( get_arg )

      return 'http_error' unless response.success?

      results = response.body['results']

      return 'not_found' if results.blank?

      item = results.first

      return 'failed' if /failed/i.match?(item['status']) || /cancelled/i.match?(item['status'])

      return 'success' if /cleanup/i.match?(item['stage']) && /success/i.match?(item['status'])

      'processing'
    rescue StandardError => e
      Rails.logger.error "Aptrust::Service.ingest_status(#{identifier}) #{e}"
      'standard_error'
    end

    attr_accessor :aptrust_config
    attr_accessor :base
    attr_accessor :debug_verbose
    attr_accessor :options

    def initialize( msg_handler:         nil,

                    aptrust_config:      nil,
                    aptrust_config_file: nil, # ignored if aptrust_config is defined

                    debug_verbose:       aptrust_uploader_debug_verbose )

      @debug_verbose = debug_verbose
      @debug_verbose ||= aptrust_uploader_debug_verbose
      @msg_handler = msg_handler
      @msg_handler ||= ::Aptrust::NULL_MSG_HANDLER

      @aptrust_config      = aptrust_config
      @aptrust_config_file = aptrust_config_file

      if @aptrust_config.blank?
        @aptrust_config = if @aptrust_config_file.present?
                            AptrustConfig.new( filename: @aptrust_config_filename )
                          else
                            AptrustConfig.new
                          end
      end

    end

    def base
      @base ||= aptrust_config.aptrust_api_url
    end

    private

      def connection
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

end
