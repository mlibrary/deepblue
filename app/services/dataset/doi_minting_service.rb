module Dataset
  class DoiMintingService
    PUBLISHER = "University of Michigan".freeze
    RESOURCE_TYPE = "Dataset".freeze

    attr :work, :metadata

    def self.mint_doi_for(work)
      Dataset::DoiMintingService.new(work).run
    end

    def initialize(work)
      @work = work
      @metadata = generate_metadata
    end

    def run
      return unless doi_server_reachable?
      work.doi = mint_doi
      work.save
      work.doi
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
        md.target = Rails.application.routes.url_helpers.hyrax_generic_work_url(id: work.id)
      end
    end

    def mint_doi
      identifier = Ezid::Identifier.create(@metadata)
      identifier.id
    end
  end
end
