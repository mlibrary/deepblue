# frozen_string_literal: true
# hyrax-orcid

module Hyrax
  module Orcid
    class UsersController < ApplicationController
      before_action :enabled?, :connected?

      def show
        render "show", layout: false
      end

      def orcid_identity
        @_user_identity ||= OrcidIdentity.find_by(orcid_id: orcid_id)
      end
      helper_method :orcid_identity

      protected

        def orcid_id
          params.require(:orcid_id)
        end

        def connected?
          return if orcid_identity.present?

          raise ActiveRecord::RecordNotFound, "User has not linked their account to ORCID"
        end

        def enabled?
          return if Flipflop.enabled?(:hyrax_orcid)

          raise ActionController::RoutingError, "The feature is not currently enabled"
        end
    end
  end
end
