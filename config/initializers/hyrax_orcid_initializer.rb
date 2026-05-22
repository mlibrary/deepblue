# frozen_string_literal: true
# hyrax-orcid -- Created this to replace some of the definitions in Hyrax::Orcid::Engine

ORCID_INTEGRATION_SERVICE_SETUP_DEBUG_VERBOSE = true

# try this here
module Hyrax
  module Orcid
    class Error < StandardError; end
  end
end

# try these here -- copied from Hyrax::Orcid::Engine
Hyrax::HyraxHelperBehavior.include Hyrax::Orcid::HelperBehavior  # Add any required helpers, for routes, api metadata etc
if Rails.configuration.use_bolognese
# Hyrax::WorkIndexer.include Hyrax::Orcid::WorkIndexerBehavior     # Allow the JSON fields to be indexed individually
# Insert our custom reader and writer to process works ready before publishing
Bolognese::Metadata.prepend Bolognese::Writers::Orcid::XmlWriter
Bolognese::Metadata.prepend Bolognese::Readers::Orcid::HyraxWorkReader
end # if Rails.configuration.use_bolognese

::Hyrax::OrcidIntegrationService.setup do |config|

  puts "::Hyrax::OrcidIntegrationService.setup" if ORCID_INTEGRATION_SERVICE_SETUP_DEBUG_VERBOSE
  # :sandbox or :production
  # case Rails.configuration.hostname
  # when ::Deepblue::InitializationConstants::HOSTNAME_PROD
  #   config.environment = :production
  # when ::Deepblue::InitializationConstants::HOSTNAME_TESTING
  #   config.environment = :sandbox
  # else
  #   config.environment = :sandbox
  # end
  puts "Rails.configuration.hostname=#{Rails.configuration.hostname}" if ORCID_INTEGRATION_SERVICE_SETUP_DEBUG_VERBOSE
  case Rails.configuration.hostname
  when ::Deepblue::InitializationConstants::HOSTNAME_PROD
    config.environment = :production
  when ::Deepblue::InitializationConstants::HOSTNAME_TESTING
    config.environment = :sandbox
  when ::Deepblue::InitializationConstants::HOSTNAME_STAGING
    config.environment = :sandbox
  when ::Deepblue::InitializationConstants::HOSTNAME_TEST
    config.environment = :sandbox
  when ::Deepblue::InitializationConstants::HOSTNAME_LOCAL
    config.environment = :sandbox
  else
    config.environment = :sandbox
  end
  puts "::Hyrax::OrcidIntegrationService.setup config.environment=#{config.environment}" if ORCID_INTEGRATION_SERVICE_SETUP_DEBUG_VERBOSE

  if Rails.configuration.use_bolognese
  config.bolognese = {
    # The work reader method, excluding the _reader suffix
    reader_method: "hyrax_json_work",
    xml_builder_class_name: "Bolognese::Writers::Orcid::HyraxXmlBuilder",
    # The writer class that provides the XML body which is sent to Orcid
    xml_writer_class_name: "Bolognese::Writers::Xml::WorkWriter"
  }
  end # if Rails.configuration.use_bolognese

  config.active_job_type = :perform_later
  config.work_types = ["YourWorkType", "GenericWork"]

end
