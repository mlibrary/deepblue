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
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
                                                 "params=#{params}",
                                                 "params[:code]=#{params[:code]}",
                                                 "params=#{params.pretty_inspect}",
                                                 "" ] if orcid_identities_controller_debug_verbose
          request_authorization
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
                                                 "@authorization_response=#{@authorization_response.pretty_inspect}",
                                                 "@authorization_response&.success?=#{@authorization_response&.success?}",
                                                 "" ] if orcid_identities_controller_debug_verbose
          if @authorization_response.blank?
            # an error will be of this form
            # https://testing.deepblue.lib.umich.edu/data/dashboard/orcid_identity/new?error=access_denied&error_description=User%20denied%20access
            if params[:error].present? && 'User denied access' == params[:error_description]
              flash[:error] = I18n.t("hyrax.orcid.preferences.create.failure", error: params[:error_description])
            else
              flash[:error] = I18n.t("hyrax.orcid.preferences.create.failure", error: params[:error_description])
            end
          elsif @authorization_response.success?
            current_user.orcid_identity_from_authorization(authorization_body)
            flash[:notice] = I18n.t("hyrax.orcid.preferences.create.success")
          else
            flash[:error] = I18n.t!("hyrax.orcid.preferences.create.failure", error: authorization_body.dig("error"))
          end

          redirect_to hyrax.dashboard_profile_path(current_user)
        end

        def update
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
                                                 "params[:id]=#{params[:id]}",
                                                 "current_user.orcid_identity=#{current_user.orcid_identity}",
                                                 "params=#{params.pretty_inspect}",
                                                 "" ] if orcid_identities_controller_debug_verbose
          begin
            orcid_identity = current_user.orcid_identity
            ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
                                                   "orcid_identity=#{orcid_identity.pretty_inspect}",
                                                   "" ] if orcid_identities_controller_debug_verbose
            if orcid_identity.update(permitted_preference_params)
              flash[:notice] = I18n.t("hyrax.orcid.preferences.update.success")
            else
              flash[:error] = I18n.t("hyrax.orcid.preferences.update.failure")
            end
          rescue Exception => e
            ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                   ::Deepblue::LoggingHelper.called_from,
                                                   "e=#{e}",
                                                   "params=#{params.pretty_inspect}",
                                                   "" ] + e.backtrace if orcid_identities_controller_debug_verbose
            flash[:error] = I18n.t("hyrax.orcid.preferences.update.failure")
          end

          redirect_back fallback_location: hyrax.dashboard_profile_path(current_user)
        end

        def destroy
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
                                                 "params[:id]=#{params[:id]}",
                                                 "current_user.orcid_identity=#{current_user.orcid_identity}",
                                                 "params=#{params.pretty_inspect}",
                                                 "" ] if orcid_identities_controller_debug_verbose
          # This is pretty ugly, but for a has_one relation we can't do a find_by! from User
          raise ActiveRecord::RecordNotFound unless current_user.orcid_identity&.id == params["id"].to_i

          revoke_authorization
          current_user.orcid_identity.destroy
          flash[:notice] = I18n.t("hyrax.orcid.preferences.destroy.success")

          redirect_back fallback_location: hyrax.dashboard_profile_path(current_user)
        end

        protected

          def permitted_preference_params
            ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
                                                   "params=#{params.pretty_inspect}",
                                                   "" ] if orcid_identities_controller_debug_verbose
            rv = params.require(:orcid_identity).permit(:work_sync_preference, profile_sync_preference: {})
            ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
                                                   "rv=#{rv.pretty_inspect}",
                                                   "" ] if orcid_identities_controller_debug_verbose
            return rv
          end

          def request_authorization
            ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
                                                   "params=#{params.pretty_inspect}",
                                                   "" ] if orcid_identities_controller_debug_verbose

            # an error will be of this form
            # https://testing.deepblue.lib.umich.edu/data/dashboard/orcid_identity/new?error=access_denied&error_description=User%20denied%20access
            @authorization_response = nil
            return if params[:error].present?

            data = {
              client_id: ::Hyrax::OrcidIntegrationService.auth[:client_id],
              client_secret: ::Hyrax::OrcidIntegrationService.auth[:client_secret],
              grant_type: "authorization_code",
              code: code
            }
            ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
                                                   "data=#{data.pretty_inspect}",
                                                   "" ] if orcid_identities_controller_debug_verbose

            @authorization_response = Faraday.post(helpers.orcid_token_uri, data.to_query, "Accept" => "application/json")
            ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
                                                   "@authorization_response=#{@authorization_response.pretty_inspect}",
                                                   "" ] if orcid_identities_controller_debug_verbose

            @authorization_response
          end

          def authorization_body
            JSON.parse(@authorization_response.body)
          end

          def code
            params.require(:code)
          end

        def revoke_authorization
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
                                                 "" ] if orcid_identities_controller_debug_verbose
          data = {
            client_id: ::Hyrax::OrcidIntegrationService.auth[:client_id],
            client_secret: ::Hyrax::OrcidIntegrationService.auth[:client_secret],
            token: current_user.orcid_identity.access_token
          }
          begin
          revoke_response = Faraday.post(helpers.orcid_oauth_uri( rest: "revoke" ), data.to_query, "Accept" => "application/json")
          rescue Exception => e
            ::Deepblue::LoggingHelper.bold_error [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
                                                   "e=#{e}",
                                                   "" ] + e.backtrace
            raise e
          end
        end
      end
    end
  end
end
