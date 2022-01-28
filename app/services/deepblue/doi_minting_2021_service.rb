# frozen_string_literal: true

module Deepblue

  module Doi
    class Error < ::StandardError; end
    class NotFoundError < ::Deepblue::Doi::Error; end
  end

  class DoiMinting2021Service

    mattr_accessor :doi_minting_2021_service_debug_verbose,
      default: ::Deepblue::DoiMintingService.doi_minting_2021_service_debug_verbose

    attr_reader :username, :password, :prefix, :mode

    def initialize(username:, password:, prefix:, mode: :production)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "username=#{username}",
                                             "password=#{password}",
                                             "prefix=#{prefix}",
                                             "mode=#{mode}",
                                             "" ] if doi_minting_2021_service_debug_verbose
      case mode&.to_sym
      when :production
        # recognized mode
      when :testing
        # recognized mode
      when :test
        # recognized mode
      else
        raise Error.new"Unrecognized mode #{mode}"
      end
      @username = username
      @password = password
      @prefix = prefix
      @mode = mode
    end

    # Mint a draft DOI without metadata or a url
    # If you already have a DOI and want to register it as a draft then go through the normal
    # process (put_metadata/register_url)
    def create_draft_doi
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "draft_doi_payload.to_json=#{draft_doi_payload.to_json}",
                                             "" ] if doi_minting_2021_service_debug_verbose
      # Use regular api instead of mds for metadata-less url-less draft doi creation
      response = connection.post('dois', draft_doi_payload.to_json, "Content-Type" => "application/vnd.api+json")
      raise Error.new("Failed creating draft DOI using #{draft_doi_payload.to_json}", response) unless response.status == 201

      JSON.parse(response.body)['data']['id']
    end

    def delete_draft_doi(doi)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "doi=#{doi}",
                                             "" ] if doi_minting_2021_service_debug_verbose
      response = mds_connection.delete("doi/#{doi}")
      raise Error.new("Failed deleting draft DOI '#{doi}'", response) unless response.status == 200

      doi
    end

    def get_metadata(doi)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "doi=#{doi}",
                                             "" ] if doi_minting_2021_service_debug_verbose
      response = mds_connection.get("metadata/#{doi}")
      raise Error.new("Failed getting DOI '#{doi}' metadata", response) unless response.status == 200

      Nokogiri::XML(response.body).remove_namespaces!
    end

    # This will mint a new draft DOI if the passed doi parameter is blank
    # The passed datacite xml needs an identifier (just the prefix when minting new DOIs)
    # Beware: This will convert registered DOIs into findable!
    def put_metadata(doi, metadata)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "doi=#{doi}",
                                             "metadata=#{metadata}",
                                             "" ] if doi_minting_2021_service_debug_verbose
      doi = prefix if doi.blank?
      response = mds_connection.put("metadata/#{doi}", metadata, { 'Content-Type': 'application/xml;charset=UTF-8' })
      raise Error.new("Failed creating metadata for DOI '#{doi}'", response) unless response.status == 201

      /^OK \((?<found_or_created_doi>.*)\)$/ =~ response.body
      found_or_created_doi
    end

    # Beware: This will make findable DOIs become registered (by setting is_active to false)
    # Otherwise this has no effect on the DOI's metadata (even when draft)
    # Beware: Attempts to delete the metadata of an unknown DOI will actually create a blank draft DOI
    def delete_metadata(doi)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "doi=#{doi}",
                                             "" ] if doi_minting_2021_service_debug_verbose
      response = mds_connection.delete("metadata/#{doi}")
      raise Error.new("Failed deleting DOI '#{doi}' metadata", response) unless response.status == 200

      doi
    end

    def get_url(doi)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "doi=#{doi}",
                                             "" ] if doi_minting_2021_service_debug_verbose
      response = mds_connection.get("doi/#{doi}")
      raise Error.new("Failed getting DOI '#{doi}' url", response) unless response.status == 200

      response.body
    end

    # Beware: This will convert draft DOIs to findable!
    # Metadata needs to be registered for a DOI before a url can be registered
    def register_url(doi, url)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "doi=#{doi}",
                                             "url=#{url}",
                                             "" ] if doi_minting_2021_service_debug_verbose
      payload = "doi=#{doi}\nurl=#{url}"
      response = mds_connection.put("doi/#{doi}", payload, { 'Content-Type': 'text/plain;charset=UTF-8' })
      raise Error.new("Failed registering url '#{url}' for DOI '#{doi}'", response) unless response.status == 201

      url
    end

    class Error < RuntimeError
      ##
      # @!attribute [r] status
      #   @return [Integer]
      attr_reader :status

      ##
      # @param msg      [String]
      # @param response [Faraday::Response]
      def initialize(msg = '', response = nil)
        if response
          @status = response.status
          msg += "\n#{@status}: #{response.reason_phrase}\n"
          msg += response.body
        end

        super(msg)
      end
    end

    private

    def connection
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "base_url=#{base_url}",
                                             "username=#{username}",
                                             # "password=#{password}",
                                             "" ] if doi_minting_2021_service_debug_verbose
      rv = Faraday.new(url: base_url) do |c|
        c.basic_auth(username, password)
        c.adapter(Faraday.default_adapter)
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ] if doi_minting_2021_service_debug_verbose
      return rv
    end

    def mds_connection
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "base_url=#{mds_base_url}",
                                             "username=#{username}",
                                             # "password=#{password}",
                                             "" ] if doi_minting_2021_service_debug_verbose
      rv = Faraday.new(url: mds_base_url) do |c|
        c.basic_auth(username, password)
        c.adapter(Faraday.default_adapter)
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ] if doi_minting_2021_service_debug_verbose
      return rv
    end

    def draft_doi_payload
      {
        "data": {
          "type": "dois",
          "attributes": {
            "prefix": "#{prefix}"
          }
        }
      }
    end

    # Ensre that `mode` is not a string
    def base_url
      case mode&.to_sym
      when :production
        ::Deepblue::DoiMintingService.production_base_url
      when :testing
        ::Deepblue::DoiMintingService.test_base_url
      when :test
        ::Deepblue::DoiMintingService.test_base_url
      else
        raise Error.new"Unrecognized mode #{mode}"
      end
      # mode&.to_sym == :production ? ::Deepblue::DoiMintingService.production_base_url
      #   : ::Deepblue::DoiMintingService.test_base_url
    end

    def mds_base_url
      case mode&.to_sym
      when :production
        ::Deepblue::DoiMintingService.production_mds_base_url
      when :testing
        ::Deepblue::DoiMintingService.test_mds_base_url
      when :test
        ::Deepblue::DoiMintingService.test_mds_base_url
      else
        raise Error.new"Unrecognized mode #{mode}"
      end
      # mode&.to_sym == :production ? ::Deepblue::DoiMintingService.production_mds_base_url
      #   : ::Deepblue::DoiMintingService.test_mds_base_url
    end

  end

end

