# frozen_string_literal: true
# hyrax-orcid

require 'rails/all'

module Hyrax
  module Orcid
    class Engine < Rails::Engine
      isolate_namespace Hyrax::Orcid

      config.before_initialize do
        # ignore # Rails.application.configure { config.eager_load = true } if Rails.env.development?

        # Rails.application.routes.prepend do
        #   mount Hyrax::Orcid::Engine => "/"
        # end
        # moved to config/routes.rb
      end

      # # Allow flipflop to load config/features.rb from the Hyrax gem:
      # initializer "configure" do
      #   Flipflop::FeatureLoader.current.append(self)
      # end

      config.after_initialize do
        # Prepend our views so they have precedence
        # moved to ::Hyrax::OrcidIntegrationService.after_initialize_callback # ActionController::Base.prepend_view_path(debug_log_helper_debug_verbose.existent)

        # Append our locales so they have precedence
        # moved to ::Hyrax::OrcidIntegrationService.after_initialize_callback # I18n.load_path += Dir[Hyrax::Orcid::Engine.root.join("config", "locales", "*.{rb,yml}")]
      end

      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize
      def self.mixins
        # added to ::User # ::User.include Hyrax::Orcid::UserBehavior

        # Add any required helpers, for routes, api metadata etc
        # added to initializer/hyrax_orcid_initializer.rb # Hyrax::HyraxHelperBehavior.include Hyrax::Orcid::HelperBehavior

        # Add the JSON processing code to the default presenter
        # presenter_behavior = ::Hyrax::OrcidIntegrationService.presenter_behavior
        # Hyrax::WorkShowPresenter.prepend presenter_behavior.constantize if presenter_behavior.present?
        # the default for this is: Hyrax::Orcid::WorkShowPresenterBehavior
        # added to Hyrax::WorkShowPresenter #

        # Allow the JSON fields to be indexed individually
        # added to initializer/hyrax_orcid_initializer.rb # Hyrax::WorkIndexer.include Hyrax::Orcid::WorkIndexerBehavior

        # All work types and their forms will require the following concerns to be included
        # Array.wrap(Hyrax::Orcid.configuration.work_types).reject(&:blank?).each do |work_type|
        #  "Hyrax::#{work_type}Form".constantize.include Hyrax::Orcid::WorkFormBehavior
        #   work_type.constantize.include Hyrax::Orcid::WorkBehavior
        # end
        # added to DeepblueForm

        # Insert our custom reader and writer to process works ready before publishing
        # moved to initializer/hyrax_orcid_initializer.rb # Bolognese::Metadata.prepend Bolognese::Writers::Orcid::XmlWriter
        # moved to initializer/hyrax_orcid_initializer.rb # Bolognese::Metadata.prepend Bolognese::Readers::Orcid::HyraxWorkReader

        # Because the Hyrax::ModelActor does not call next_actor to continue the chain,
        # for destroy requests, we require a new actor
        # actors = [Hyrax::Actors::ModelActor, Hyrax::Actors::Orcid::UnpublishWorkActor]
        # Hyrax::CurationConcern.actor_factory.insert_before(*actors)
        # moved to config/initializers/hyrax.rb

        # Insert the publish actor at the end of the chain so we only publish a fully processed work
        # Hyrax::CurationConcern.actor_factory.use Hyrax::Actors::Orcid::PublishWorkActor
        # moved to config/initializers/hyrax.rb

        # Insert an extra step in the Blacklight rendering pipeline where our JSON can be parsed
        # operation = Hyrax::Orcid.configuration.blacklight_pipeline_actor
        # ::Blacklight::Rendering::Pipeline.operations.insert(1, operation.constantize) if operation.present?
        # moved to ::Hyrax::OrcidIntegrationService.after_initialize_callback

        # Insert our JSON actor before the Model is saved
        # actor = Hyrax::Orcid.configuration.hyrax_json_actor
        # Hyrax::CurationConcern.actor_factory.insert_before Hyrax::Actors::ModelActor, actor.constantize if actor.present?
        # moved to config/initializers/hyrax.rb
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength

      # ignore # config.send(Rails.env.development? ? :to_prepare : :after_initialize) { Hyrax::Orcid::Engine.mixins }
    end
  end
end
