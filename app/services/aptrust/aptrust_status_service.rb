# frozen_string_literal: true

module Aptrust

  class AptrustStatusService

    # TODO: review
    def ingest_status(identifier) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      # For API V3 we need identifiers that look like fulcrum.org/fulcrum.org.michelt-zc77ss45g
      # and not just fulcrum.org.michelt-zc77ss45g
      response = connection.get("items?object_identifier=fulcrum.org\/#{identifier}&action=Ingest")

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

    def initialize(options = {})
      @base = options[:base] # TODO: review
      @base ||= begin # TODO: review
        filename = Rails.root.join('config', 'aptrust.yml') # TODO: review
        @yaml = YAML.safe_load(File.read(filename)) if File.exist?(filename) # TODO: review
        @yaml ||= {} # TODO: review
        @yaml['AptrustApiUrl'] # TODO: review
      end
    end

    private

      # TODO: review
      def connection
        @connection ||= Faraday.new(@base) do |conn|
          conn.headers = {
            accept: "application/json",
            content_type: "application/json",
            "X-Pharos-API-User" => @yaml['AptrustApiUser'],
            "X-Pharos-API-Key" => @yaml['AptrustApiKey']
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
