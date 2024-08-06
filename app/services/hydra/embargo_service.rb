# frozen_string_literal: true
# Reviewed: hyrax4 -- hydra-access-controls-12.1.0

module Hydra

  module EmbargoService

    HYDRA_EMBARGO_SERVICE_DEBUG_VERBOSE = false

    class << self
      #
      # Methods for Querying Repository to find Embargoed Objects
      #

      # Returns all assets with embargo release date set to a date in the past
      def assets_with_expired_embargoes
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "" ] if HYDRA_EMBARGO_SERVICE_DEBUG_VERBOSE
        ::PersistHelper.where("#{Hydra.config.permissions.embargo.release_date}:[* TO NOW]")
      end

      # Returns all assets with embargo release date set
      #   (assumes that when lease visibility is applied to assets
      #    whose leases have expired, the lease expiration date will be removed from its metadata)
      def assets_under_embargo
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "" ] if HYDRA_EMBARGO_SERVICE_DEBUG_VERBOSE
        ::PersistHelper.where("#{Hydra.config.permissions.embargo.release_date}:[* TO *]")
      end

      # Returns all assets that have had embargoes deactivated in the past.
      def assets_with_deactivated_embargoes
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "" ] if HYDRA_EMBARGO_SERVICE_DEBUG_VERBOSE
        ::PersistHelper.where("#{Hydra.config.permissions.embargo.history}:*")
      end

    end

  end

end
