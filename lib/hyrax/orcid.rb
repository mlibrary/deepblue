# frozen_string_literal: true
# hyrax-orcid

require "hyrax/orcid/version"
require "hyrax/orcid/engine"
require "hyrax/orcid/errors"
require "flipflop"
require 'bolognese' if Rails.configuration.use_bolognese

module Hyrax
  module Orcid
    # Setup a configuration class that allows users to override these settings
    # with their own configuration, or add ENV variables.
    class << self
      attr_accessor :configuration
    end

    def self.configure
      load_configuration

      yield(configuration)
    end

    # Use the defaults and reset the memoized variable
    def self.reset_configuration
      self.configuration = nil

      load_configuration
    end

    def self.load_configuration
      self.configuration ||= Configuration.new
    end

    class Configuration
      attr_accessor :environment,
                    :auth,
                    :bolognese,
                    :active_job_type,
                    :hyrax_json_actor,
                    :blacklight_pipeline_actor,
                    :work_types,
                    :presenter_behavior

      # rubocop:disable Metrics/MethodLength
      def initialize
        @environment = ENV["ORCID_ENVIRONMENT"] || :sandbox

        @auth = {
          client_id: ENV["ORCID_CLIENT_ID"],
          client_secret: ENV["ORCID_CLIENT_SECRET"],
          redirect_url: ENV["ORCID_AUTHORIZATION_REDIRECT_URL"]
        }

        @bolognese = {
          # The work reader method, excluding the _reader suffix
          reader_method: "hyrax_json_work",
          # The XML builder class that provides the XML body which is sent to Orcid
          xml_builder_class_name: "Bolognese::Writers::Orcid::HyraxXmlBuilder"
        }

        # How to perform the active jobs that are created. This is useful for debugging the jobs and
        # generated XML or if you want to run all jobs inline.
        # `:perform_later` or `:perform_now`
        @active_job_type = :perform_now

        # Allow these to be set by implementing host, otherwise it is impossible to remove them from the middleware stack
        @hyrax_json_actor = "Hyrax::Actors::Orcid::JSONFieldsActor"
        @blacklight_pipeline_actor = "Hyrax::Orcid::Blacklight::Rendering::PipelineJsonExtractor"

        # An array of work types that should implement the creator/contributor Orcid json fields
        @work_types = ["GenericWork"]

        @presenter_behavior = "Hyrax::Orcid::WorkShowPresenterBehavior"
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
