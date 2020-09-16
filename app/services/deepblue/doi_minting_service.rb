# frozen_string_literal: true

module Deepblue

  class DoiMintingService

    @@doi_minting_service_debug_verbose = false

    @@doi_mint_on_publication_event
    @@doi_minting_service_integration_enabled
    @@doi_minting_service_integration_hostnames
    @@doi_minting_service_integration_hostnames_prod
    @@doi_publisher_name
    @@doi_resource_type
    @@doi_resource_types

    mattr_accessor :doi_mint_on_publication_event,
                   :doi_minting_service_debug_verbose,
                   :doi_minting_service_integration_enabled,
                   :doi_minting_service_integration_hostnames,
                   :doi_minting_service_integration_hostnames_prod,
                   :doi_publisher_name,
                   :doi_resource_type,
                   :doi_resource_types

    @@_setup_ran = false

    def self.setup
      yield self if @@_setup_ran == false
      @@_setup_ran = true
    end

    def self.mint_doi_for( curation_concern:, current_user:, target_url: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "current_user=#{current_user}",
                                             "target_url=#{target_url}",
                                             "" ] if DoiMintingService.doi_minting_service_debug_verbose
      service = Deepblue::DoiMintingService.new( curation_concern: curation_concern,
                                                 current_user: current_user,
                                                 target_url: target_url )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "about to call service.run",
                                             "" ] if DoiMintingService.doi_minting_service_debug_verbose
      service.run
    rescue Exception => e # rubocop:disable Lint/RescueException
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "current_user=#{current_user}",
                                             "target_url=#{target_url}",
                                             "rescue exception -- Exception: #{e.class}: #{e.message} at #{e.backtrace[0]}",
                                             "" ] if DoiMintingService.doi_minting_service_debug_verbose
      Rails.logger.debug "DoiMintingService.mint_doi_for( curation_concern id = #{curation_concern.id},"\
                         " current_user = #{current_user}, target_url = #{target_url} )"\
                         " rescue exception -- Exception: #{e.class}: #{e.message} at #{e.backtrace[0]}"
      unless curation_concern.nil?
        curation_concern.reload # consider locking curation_concern
        curation_concern.doi = nil
        curation_concern.save
        curation_concern.reload
        curation_concern.doi
      end
      raise
    end

    attr :current_user, :curation_concern, :metadata, :target_url

    def initialize( curation_concern:, current_user:, target_url: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "" ] if DoiMintingService.doi_minting_service_debug_verbose
      @curation_concern = curation_concern
      @current_user = current_user
      @target_url = target_url
      @metadata = generate_metadata
    end

    def run
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "" ] if DoiMintingService.doi_minting_service_debug_verbose
      rv = doi_server_reachable?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "doi_server_reachable? rv=#{rv}",
                                             "" ] if DoiMintingService.doi_minting_service_debug_verbose
      return mint_doi_failed unless rv
      curation_concern.reload # consider locking curation_concern
      curation_concern.doi = mint_doi
      curation_concern.save
      curation_concern.reload
      curation_concern.provenance_mint_doi( current_user: current_user, event_note: 'DoiMintingService' )
      curation_concern.doi
    end

    def self.print_ezid_config
      config = Ezid::Client.config
      puts "Ezid::Client.config.host = #{config.host}"
      puts "Ezid::Client.config.port = #{config.port}"
      puts "Ezid::Client.config.user = #{config.user}"
      puts "Ezid::Client.config.password = #{config.password}"
      puts "Ezid::Client.config.default_shoulder = #{config.default_shoulder}"
    end

    def ezid_config
      config = Ezid::Client.config
      return [ "Ezid::Client.config.host = #{config.host}",
               "Ezid::Client.config.port = #{config.port}",
               "Ezid::Client.config.user = #{config.user}",
               # "Ezid::Client.config.password = #{config.password}",
               "Ezid::Client.config.default_shoulder = #{config.default_shoulder}" ]
    end

    private

      # Any error raised during connection is considered false
      def doi_server_reachable?
        Ezid::Client.new.server_status.up? rescue false
      end

      def generate_metadata
        Ezid::Metadata.new.tap do |md|
          md.datacite_title = curation_concern.title.first
          md.datacite_publisher = DoiMintingService.doi_publisher_name
          md.datacite_publicationyear = Date.today.year.to_s
          md.datacite_resourcetype = DoiMintingService.doi_resource_type
          md.datacite_creator = if curation_concern.work?
                                  curation_concern.creator.join(';')
                                else
                                  curation_concern.parent.creator.join(';')
                                end
          # md.target = Rails.application.routes.url_helpers.hyrax_data_set_url(id: curation_concern.id)
          md.target = target_url
        end
      end

      def mint_doi
        # identifier = Ezid::Identifier.create(@metadata)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "curation_concern.id=#{curation_concern.id}",
                                               "metadata=#{metadata}",
                                               "" ] if DoiMintingService.doi_minting_service_debug_verbose

        # Rails.logger.debug "DoiMintingService.mint_doi( #{metadata} )"
        # msg = ezid_config.join("\n")
        # Rails.logger.debug msg
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "curation_concern.id=#{curation_concern.id}",
                                               "", ] + ezid_config if DoiMintingService.doi_minting_service_debug_verbose
        shoulder = Ezid::Client.config.default_shoulder
        identifier = Ezid::Identifier.mint( shoulder, @metadata )
        identifier.id
      end

      def mint_doi_failed
        Rails.logger.error "DoiMintingService.mint_doi_failed curation_concern id = #{curation_concern.id}"
        curation_concern.reload # consider locking curation_concern
        curation_concern.doi = nil
        curation_concern.save
        curation_concern.reload
        curation_concern.doi
      end

  end

end
