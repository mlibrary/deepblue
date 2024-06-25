# frozen_string_literal: true
# hyrax-orcid

module Hyrax
  module Orcid
    module Dashboard
      class OrcidIdentitiesController < ApplicationController
        include Hyrax::Orcid::RouteHelper

        mattr_accessor :orcid_identities_controller_debug_verbose, default: false

        with_themed_layout "dashboard"
        before_action :authenticate_user!

        def new
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "params=#{params}",
                                                 "params[:code]=#{params[:code]}",
                                                 "" ] if orcid_identities_controller_debug_verbose
          request_authorization
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "@authorization_response.success?=#{@authorization_response.success?}",
                                                 "" ] if orcid_identities_controller_debug_verbose
          if @authorization_response.success?
            current_user.orcid_identity_from_authorization(authorization_body)
            flash[:notice] = I18n.t("hyrax.orcid.preferences.create.success")
          else
            flash[:error] = I18n.t!("hyrax.orcid.preferences.create.failure", error: authorization_body.dig("error"))
          end

          redirect_to hyrax.dashboard_profile_path(current_user)
        end

        def update
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "params[:id]=#{params[:id]}",
                                                 "current_user.orcid_identity=#{current_user.orcid_identity}",
                                                 "" ] if orcid_identities_controller_debug_verbose
          if current_user.orcid_identity.update(permitted_preference_params)
            flash[:notice] = I18n.t("hyrax.orcid.preferences.update.success")
          else
            flash[:error] = I18n.t("hyrax.orcid.preferences.update.failure")
          end

          redirect_back fallback_location: hyrax.dashboard_profile_path(current_user)
        end

        def destroy
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "params[:id]=#{params[:id]}",
                                                 "current_user.orcid_identity=#{current_user.orcid_identity}",
                                                 "" ] if orcid_identities_controller_debug_verbose
          # This is pretty ugly, but for a has_one relation we can't do a find_by! from User
          raise ActiveRecord::RecordNotFound unless current_user.orcid_identity&.id == params["id"].to_i

          current_user.orcid_identity.destroy
          flash[:notice] = I18n.t("hyrax.orcid.preferences.destroy.success")

          redirect_back fallback_location: hyrax.dashboard_profile_path(current_user)
        end

        protected

          def permitted_preference_params
            params.require(:orcid_identity).permit(:work_sync_preference, profile_sync_preference: {})
          end

          def request_authorization
            data = {
              client_id: ::Hyrax::OrcidIntegrationService.auth[:client_id],
              client_secret: ::Hyrax::OrcidIntegrationService.auth[:client_secret],
              grant_type: "authorization_code",
              code: code
            }

            @authorization_response = Faraday.post(helpers.orcid_token_uri, data.to_query, "Accept" => "application/json")
          end

          def authorization_body
            JSON.parse(@authorization_response.body)
          end

          def code
            params.require(:code)
          end
      end
    end
  end
end
