# frozen_string_literal: true
# hyrax-orcid

module Hyrax
  module Orcid
    class UsersController < ApplicationController

      mattr_accessor :hyrax_orcid_users_controller_debug_verbose, default: false

      before_action :enabled? #, :connected?

      def show
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "params[:orcid_id]=#{params[:orcid_id]}",
                                               "orcid_identity=#{orcid_identity}",
                                               "" ] if hyrax_orcid_users_controller_debug_verbose
        render "show", layout: false
      end

      def orcid_identity
        @_user_identity ||= find_user_identity
      end
      helper_method :orcid_identity

      protected

      def find_user_identity
        id = orcid_id
        if id =~ /^\d+$/
          OrcidIdentity.find_by(id: id)
        else
          OrcidIdentity.find_by(orcid_id: id)
        end
      end

        def orcid_id
          params.require(:orcid_id)
        end

        def connected?
          return if orcid_identity.present?

          raise ActiveRecord::RecordNotFound, "User has not linked their account to ORCID"
        end

        def enabled?
          return if Flipflop.hyrax_orcid?

          raise ActionController::RoutingError, "The feature is not currently enabled"
        end
    end
  end
end
