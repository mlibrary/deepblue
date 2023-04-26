# frozen_string_literal: true
# hyrax-orcid

module Hyrax
  module Orcid
    module UrlHelper
      include RouteHelper

      ORCID_API_VERSION = "v2.1"

      def orcid_profile_uri(profile_id)
        "https://#{orcid_domain}/#{profile_id}"
      end

      # TODO: Move ENV vars to options panel
      def orcid_authorize_uri
        params = {
          client_id: ::Hyrax::OrcidIntegrationService.auth[:client_id],
          redirect_uri: ::Hyrax::OrcidIntegrationService.auth[:redirect_url],
          scope: "/activities/update /read-limited",
          response_type: "code"
        }

        "https://#{orcid_domain}/oauth/authorize?#{params.to_query}"
      end

      def orcid_token_uri
        "https://#{orcid_domain}/oauth/token"
      end

      # TODO: Test me
      # Ensure production/dev domains have correct domain
      def orcid_api_uri(orcid_id, endpoint, put_code = nil)
        [
          "https://api.#{orcid_domain}",
          ORCID_API_VERSION,
          orcid_id,
          endpoint,
          put_code
        ].compact.join("/")
      end

      protected

        def orcid_domain
          "#{'sandbox.' unless orcid_production_environment?}orcid.org"
        end

        def orcid_production_environment?
          ::Hyrax::OrcidIntegrationService.environment.to_sym == :production
        end
    end
  end
end
