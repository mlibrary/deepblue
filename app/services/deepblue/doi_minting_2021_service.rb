# frozen_string_literal: true

module Deepblue

  module Doi
    class Error < ::StandardError; end
    class NotFoundError < ::Deepblue::Doi::Error; end
  end

  class DoiMinting2021Service

    mattr_accessor :doi_minting_2021_service_debug_verbose,
      default: ::Deepblue::DoiMintingService.doi_minting_2021_service_debug_verbose

    attr_reader :username, :password, :prefix, :publisher, :mode, :debug_verbose, :debug_verbose_puts

    def initialize( username:,
                    password:,
                    prefix:,
                    publisher:,
                    mode: :production,
                    debug_verbose: doi_minting_2021_service_debug_verbose,
                    debug_verbose_puts: false )

      @debug_verbose ||= doi_minting_2021_service_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "username=#{username}",
                                             #"password=#{password}",
                                             "prefix=#{prefix}",
                                             "mode=#{mode}",
                                             "debug_verbose=#{debug_verbose}",
                                             "" ], bold_puts: debug_verbose_puts if debug_verbose
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
      @publisher = publisher
      @mode = mode
    end

    # Mint a draft DOI without metadata or a url
    # If you already have a DOI and want to register it as a draft then go through the normal
    # process (put_metadata/register_url)
    def create_draft_doi
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "draft_doi_payload.to_json=#{draft_doi_payload.to_json}",
                                             "" ], bold_puts: debug_verbose_puts if debug_verbose
      # Use regular api instead of mds for metadata-less url-less draft doi creation
      response = connection.post('dois', draft_doi_payload.to_json, "Content-Type" => "application/vnd.api+json")
      unless response.status == 201
        raise Error.new("Failed creating draft DOI using #{draft_doi_payload.to_json}", response)
      end
      JSON.parse(response.body)['data']['id']
    end

    def delete_draft_doi(doi)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "doi=#{doi}",
                                             "" ], bold_puts: debug_verbose_puts if debug_verbose
      response = mds_connection.delete("doi/#{doi}")
      raise Error.new("Failed deleting draft DOI '#{doi}'", response) unless response.status == 200

      doi
    end

    def doi_pending?( doi )
      ::Deepblue::DoiBehavior.doi_pending?( doi: doi )
    end

    def get_metadata(doi)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "doi=#{doi}",
                                             "" ], bold_puts: debug_verbose_puts if debug_verbose
      return doi if doi.blank? || doi_pending?( doi )
      response = mds_connection.get("metadata/#{doi}")
      raise Error.new("Failed getting DOI '#{doi}' metadata", response) unless response.status == 200

      Nokogiri::XML(response.body).remove_namespaces!
    end

    def get_metadata_raw(doi)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "doi=#{doi}",
                                             "" ], bold_puts: debug_verbose_puts if debug_verbose
      return "" if doi.blank? || doi_pending?( doi )
      response = mds_connection.get("metadata/#{doi}")
      raise Error.new("Failed getting DOI '#{doi}' metadata", response) unless response.status == 200

      response.body
    end

    def get_metadata_as_json(doi, raise_error: true )
      response = connection.get("dois/#{doi_url}")
      if 200 != response.status
        raise Error.new("Failed getting DOI '#{doi}' metadata", response) if raise_error
        return nil
      end
      JSON.parse(response.body)
    end

    # This will mint a new draft DOI if the passed doi parameter is blank
    # The passed datacite xml needs an identifier (just the prefix when minting new DOIs)
    # Beware: This will convert registered DOIs into findable!
    def put_metadata( doi, metadata, msg_handler: )
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "doi=#{doi}",
                               "metadata=",
                               metadata.pretty_inspect,
                               "" ] if msg_handler.debug_verbose

      doi = prefix if doi.blank? || doi_pending?( doi )
      path = "metadata/#{doi}"
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "doi=#{doi}",
                               "path=#{path}",
                               "" ] if msg_handler.debug_verbose
      # return false unless Rails.env.production?

      response = mds_connection.put( path, metadata, { 'Content-Type': 'application/xml;charset=UTF-8' })
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
                                             "" ], bold_puts: debug_verbose_puts if debug_verbose
      return doi if doi.blank? || doi_pending?( doi )
      response = mds_connection.delete("metadata/#{doi}")
      raise Error.new("Failed deleting DOI '#{doi}' metadata", response) unless response.status == 200
      doi
    end

    def get_url(doi, raise_error: true)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "doi=#{doi}",
                                             "" ], bold_puts: debug_verbose_puts if debug_verbose
      response = mds_connection.get("doi/#{doi}")
      unless response.status == 200
        return nil unless raise_error
        raise Error.new("Failed getting DOI '#{doi}' url", response)
      end

      response.body
    end

    # Beware: This will convert draft DOIs to findable!
    # Metadata needs to be registered for a DOI before a url can be registered
    def register_url(doi, url)
      # NOTE: this doi needs to be sans leading "doi:"
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "doi=#{doi}",
                                             "url=#{url}",
                                             "" ], bold_puts: debug_verbose_puts if debug_verbose
      payload = "doi=#{doi}\nurl=#{url}"
      response = mds_connection.put("doi/#{doi}", payload, { 'Content-Type': 'text/plain;charset=UTF-8' })
      raise Error.new("Failed registering url '#{url}' for DOI '#{doi}'", response) unless response.status == 201
      url
    end

    def doi_hide_payload()
      {
        "data": {
          "attributes": {
            "event": "hide",
          }
        }
      }
    end

    def doi_hide(doi)
      payload = doi_hide_payload
      response = connection.put("dois/#{doi}", payload.to_json, { 'Content-Type': 'application/vnd.api+json' })
      unless response.status == 200
        raise Error.new("Failed hide doi using #{payload.to_json}", response)
        #puts "Failed hide doi using #{payload.to_json}: #{response.pretty_inspect}"
      end
      JSON.parse(response.body)['data']['id']
      #response
    end

    def doi_hide2(doi)
      payload = doi_hide_payload
      response = connection.put("dois/#{doi}", payload.to_json, { 'Content-Type': 'application/vnd.api+json' })
      unless response.status == 200
        raise Error.new("Failed hide doi using #{payload.to_json}", response)
        #puts "Failed hide doi using #{payload.to_json}: #{response.pretty_inspect}"
      end
      JSON.parse(response.body)['data']['id']
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

    # private # lets not bother with private stuff until this is actually working

    def connection
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "base_url=#{base_url}",
                                             "username=#{username}",
                                             # "password=#{password}",
                                             "" ], bold_puts: debug_verbose_puts if debug_verbose
      rv = Faraday.new(url: base_url) do |c|
        # c.basic_auth(username, password)
        if Gem::Version.new(Faraday::VERSION) < Gem::Version.new('2')
          c.request :basic_auth, username, password
        else
          c.request :authorization, :basic, username, password
        end
        c.adapter(Faraday.default_adapter)
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ], bold_puts: debug_verbose_puts if debug_verbose
      return rv
    end

    def mds_connection
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "base_url=#{mds_base_url}",
                                             "username=#{username}",
                                             # "password=#{password}",
                                             "" ], bold_puts: debug_verbose_puts if debug_verbose
      rv = Faraday.new(url: mds_base_url) do |c|
        # c.basic_auth(username, password)
        if Gem::Version.new(Faraday::VERSION) < Gem::Version.new('2')
          c.request :basic_auth, username, password
        else
          c.request :authorization, :basic, username, password
        end
        c.adapter(Faraday.default_adapter)
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ], bold_puts: debug_verbose_puts if debug_verbose
      return rv
    end

    def draft_doi_payload
      {
        "data": {
          "type": "dois",
          "attributes": {
            "prefix": "#{prefix}",
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

