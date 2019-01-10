# frozen_string_literal: true

module Deepblue

  class DoiMintingService

    PUBLISHER = "University of Michigan".freeze
    RESOURCE_TYPE = "Dataset".freeze

    attr :work, :metadata

    def self.mint_doi_for(work)
      Rails.logger.debug "DoiMintingService.mint_doi_for( work id = #{work.id} )"
      service = Deepblue::DoiMintingService.new( work )
      Rails.logger.debug "DoiMintingService.mint_doi_for calling run"
      service.run
    rescue Exception => e # rubocop:disable Lint/RescueException
      Rails.logger.debug "DoiMintingService.mint_doi_for( work id = #{work.id} ) rescue exception -- Exception: #{e.class}: #{e.message} at #{e.backtrace[0]}"
      unless work.nil?
        work.doi = nil
        work.save
        work.doi
      end
      raise
    end

    def initialize(work)
      Rails.logger.debug "DoiMintingService.initalize( work id = #{work.id} )"
      @work = work
      @metadata = generate_metadata
    end

    def run
      Rails.logger.debug "DoiMintingService.run( work id = #{work.id} )"
      rv = doi_server_reachable?
      Rails.logger.debug "DoiMintingService.run doi_server_reachable?=#{rv}"
      return mint_doi_failed unless rv
      work.doi = mint_doi
      work.save
      work.doi
    end

    def self.print_ezid_config
      config = Ezid::Client.config
      puts "Ezid::Client.config.host = #{config.host}"
      puts "Ezid::Client.config.port = #{config.port}"
      # puts "Ezid::Client.config.use_ssl = #{config.use_ssl}"
      puts "Ezid::Client.config.user    = #{config.user}"
      puts "Ezid::Client.config.password = #{config.password}"
      puts "Ezid::Client.config.default_shoulder = #{config.default_shoulder}"
    end

    def ezid_config
      config = Ezid::Client.config
      return [ "Ezid::Client.config.host = #{config.host}",
               "Ezid::Client.config.port = #{config.port}",
               "Ezid::Client.config.user    = #{config.user}",
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
          md.datacite_title = work.title.first
          md.datacite_publisher = PUBLISHER
          md.datacite_publicationyear = Date.today.year.to_s
          md.datacite_resourcetype= RESOURCE_TYPE
          md.datacite_creator=work.creator.join(';')
          md.target = Rails.application.routes.url_helpers.hyrax_data_set_url(id: work.id)
        end
      end

      def mint_doi
        # identifier = Ezid::Identifier.create(@metadata)
        Rails.logger.debug "DoiMintingService.mint_doi( #{metadata} )"
        msg = ezid_config.join("\n")
        Rails.logger.debug msg
        shoulder = Ezid::Client.config.default_shoulder
        identifier = Ezid::Identifier.mint( shoulder, @metadata )
        identifier.id
      end

      def mint_doi_failed
        Rails.logger.error "DoiMintingService.mint_doi_failed work id = #{work.id}"
        work.doi = nil
        work.save
        work.doi
      end

  end

end
