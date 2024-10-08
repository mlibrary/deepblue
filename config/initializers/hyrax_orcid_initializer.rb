# frozen_string_literal: true
# hyrax-orcid -- Created this to replace some of the definitions in Hyrax::Orcid::Engine

if Rails.configuration.use_bolognese

# try this here
module Hyrax
  module Orcid
    class Error < StandardError; end
  end
end

# try these here -- copied from Hyrax::Orcid::Engine
Hyrax::HyraxHelperBehavior.include Hyrax::Orcid::HelperBehavior  # Add any required helpers, for routes, api metadata etc
# Hyrax::WorkIndexer.include Hyrax::Orcid::WorkIndexerBehavior     # Allow the JSON fields to be indexed individually
# Insert our custom reader and writer to process works ready before publishing
Bolognese::Metadata.prepend Bolognese::Writers::Orcid::XmlWriter
Bolognese::Metadata.prepend Bolognese::Readers::Orcid::HyraxWorkReader

::Hyrax::OrcidIntegrationService.setup do |config|

  ORCID_INTEGRATION_SERVICE_SETUP_DEBUG_VERBOSE = true

  # :sandbox or :production
  case Rails.configuration.hostname
  when ::Deepblue::InitializationConstants::HOSTNAME_PROD
    config.environment = :production
  when ::Deepblue::InitializationConstants::HOSTNAME_TESTING
    config.environment = :sandbox
  else
    config.environment = :sandbox
  end

  config.bolognese = {
    # The work reader method, excluding the _reader suffix
    reader_method: "hyrax_json_work",
    xml_builder_class_name: "Bolognese::Writers::Orcid::HyraxXmlBuilder",
    # The writer class that provides the XML body which is sent to Orcid
    xml_writer_class_name: "Bolognese::Writers::Xml::WorkWriter"
  }

  config.active_job_type = :perform_later
  config.work_types = ["YourWorkType", "GenericWork"]

end
end # if Rails.configuration.use_bolognese
