# frozen_string_literal: true
# hyrax-orcid

require "flipflop"
require "bolognese"

module Hyrax

  module OrcidIntegrationService

    @@_setup_ran = false
    @@_setup_failed = false

    def self.setup
      yield self unless @@_setup_ran
      @@_setup_ran = true
    rescue Exception => e # rubocop:disable Lint/RescueException
      @@_setup_failed = true
      msg = "#{e.class}: #{e.message} at #{e.backtrace.join("\n")}"
      # rubocop:disable Rails/Output
      puts msg
      # rubocop:enable Rails/Output
      Rails.logger.error msg
      raise e
    end

    mattr_accessor :hyrax_orcid_debug_verbose,                     default: false
    mattr_accessor :hyrax_orcid_actors_debug_verbose,              default: false
    mattr_accessor :hyrax_orcid_integration_service_debug_verbose, default: false
    mattr_accessor :hyrax_orcid_jobs_debug_verbose,                default: false
    mattr_accessor :hyrax_orcid_publisher_service_debug_verbose,   default: false
    mattr_accessor :hyrax_orcid_strategy_debug_verbose,            default: false
    mattr_accessor :orcid_user_behavior_debug_verbose,             default: false

    mattr_accessor :active_job_type,           default: :perform_later
    mattr_accessor :auth,                                   default: {
      client_id: Settings.hyrax_orcid.client_id,
      client_secret: Settings.hyrax_orcid.client_secret,
      # The authorisation return URL you entered when creating the Orcid Application.
      # Should be your repository URL and `/dashboard/orcid_identity/new`
      redirect_url: Settings.hyrax_orcid.redirect_url
    }
    mattr_accessor :blacklight_pipeline_actor, default: "Hyrax::Orcid::Blacklight::Rendering::PipelineJsonExtractor"
    mattr_accessor :bolognese,                               default: {
      # The work reader method, excluding the _reader suffix
      reader_method: "hyrax_json_work",
      xml_builder_class_name: "Bolognese::Writers::Orcid::HyraxXmlBuilder",
      # The writer class that provides the XML body which is sent to Orcid
      xml_writer_class_name: "Bolognese::Writers::Xml::WorkWriter"
    }
    mattr_accessor :environment,               default: :sandbox
    mattr_accessor :hyrax_json_actor,          default: "Hyrax::Actors::Orcid::JSONFieldsActor"
    mattr_accessor :presenter_behavior,        default: "Hyrax::Orcid::WorkShowPresenterBehavior"
    mattr_accessor :work_types,                default: ["DataSet"]

    def self.after_initialize_callback( debug_verbose: hyrax_orcid_integration_service_debug_verbose )

      puts "Begin after_initialize_callback..." if debug_verbose

      # operation = ::Hyrax::OrcidIntegrationService.blacklight_pipeline_actor
      # ::Blacklight::Rendering::Pipeline.operations.insert(1, operation.constantize) if operation.present?
      ::Blacklight::Rendering::Pipeline.operations.insert(1, Hyrax::Orcid::Blacklight::Rendering::PipelineJsonExtractor)

      # is this necessary?
      # # Prepend our views so they have precedence
      # ActionController::Base.prepend_view_path(paths["app/views"].existent)

      # skip this, will load them from the usual config directories
      # Append our locales so they have precedence
      #I18n.load_path += Dir[Hyrax::Orcid::Engine.root.join("config", "locales", "*.{rb,yml}")]

      puts "End after_initialize_callback..." if debug_verbose

    end

  end

end
