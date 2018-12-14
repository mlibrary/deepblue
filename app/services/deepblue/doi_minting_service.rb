# frozen_string_literal: true

module Deepblue

  class DoiMintingService

    PUBLISHER = "University of Michigan"
    RESOURCE_TYPE = "Dataset"

    attr_reader :work, :metadata

    def self.mint_doi_for(work)
      Umrdr::DoiMintingService.new(work).run
    end

    def initialize(work)
      Rails.logger.debug "DoiMintingService.initalize( work id = #{work.id} )"
      DoiMintingService.print_ezid_config
      @work = work
      @metadata = generate_metadata
    end

    def run
      Rails.logger.debug "DoiMintingService.run( work id = #{work.id} )"
      return unless doi_server_reachable?
      work.doi = mint_doi
      work.save
      work.doi
    end

    def self.print_ezid_config
      config = Ezid::Client.config
      LoggingHelper.bold_debug [ "Ezid::Client.config.host = #{config.host}",
                                 "Ezid::Client.config.port = #{config.port}",
                                 "Ezid::Client.config.user    = #{config.user}",
                                 "Ezid::Client.config.password = #{config.password}",
                                 "Ezid::Client.config.default_shoulder = #{config.default_shoulder}"]
    end

    private

      # Any error raised during connection is considered false
      def doi_server_reachable?
        Ezid::Client.new.server_status.up?
      rescue
        false
      end

      def generate_metadata
        Ezid::Metadata.new.tap do |md|
          md.datacite_title = work.title.first
          md.datacite_publisher = PUBLISHER
          md.datacite_publicationyear = Date.today.year.to_s
          md.datacite_resourcetype = RESOURCE_TYPE
          md.datacite_creator = work.creator.join(';')
          md.target = Rails.application.routes.url_helpers.hyrax_data_set_url( id: work.id )
        end
      end

      def mint_doi
        # identifier = Ezid::Identifier.create(@metadata)
        Rails.logger.debug "DoiMintingService.mint_doi( #{metadata} )"
        shoulder = Ezid::Client.config.default_shoulder
        identifier = Ezid::Identifier.mint( shoulder, @metadata )
        identifier.id
      end

  end

end
