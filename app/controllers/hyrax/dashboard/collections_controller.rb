# frozen_string_literal: true

require File.join( Gem::Specification.find_by_name("hyrax").full_gem_path, "app/controllers/hyrax/dashboard/collections_controller.rb" )

module Hyrax

  module Dashboard

    # monkey patch Hyrax::Dashboard::CollectionsController

    ## Shows a list of all collections to the admins
    class CollectionsController < Hyrax::My::CollectionsController

      include Deepblue::CollectionsControllerBehavior

      EVENT_NOTE = 'Hyrax::Dashboard::CollectionsController'
      PARAMS_KEY = 'collection'

      ## monkey patch overrides

      alias_method :monkey_after_create, :after_create
      alias_method :monkey_destroy, :destroy

      def after_create
        monkey_after_create
        provenance_log_create
        email_rds_create
      end

      def destroy
        provenance_log_destroy
        email_rds_destroy
        monkey_destroy
      end

      ## end monkey patch overrides

      before_action :provenance_log_update_before, only: [:update]
      after_action :provenance_log_update_after, only: [:update]

      def curation_concern
        @collection ||= ActiveFedora::Base.find(params[:id])
      end

      def default_event_note
        EVENT_NOTE
      end

      def params_key
        PARAMS_KEY
      end

    end

  end

end
