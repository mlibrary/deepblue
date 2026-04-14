# frozen_string_literal: true
# Reviewed: heliotrope

# this class is specific to UMich authentication only
class SessionsController < ApplicationController

  mattr_accessor :session_controller_debug_verbose, default: false
  mattr_accessor :session_controller_skip_redirect_on_logout, default: false

  def destroy
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
                                           "" ] if session_controller_debug_verbose
    if user_signed_in?
      sso_logout
    else
      logout_now
    end
  end

  def new
    raise unless Rails.configuration.authentication_method == "umich"
    if user_signed_in?
      Rails.logger.debug "[AUTHN] sessions#new, redirecting" if session_controller_debug_verbose
      # redirect to where user came from (see Devise::Controllers::StoreLocation#stored_location_for)
      unless session_controller_skip_redirect_on_logout
        redirect_to stored_location_for(:user) || hyrax.dashboard_path
      end
    else
      Rails.logger.debug "[AUTHN] sessions#new, failed because user_signed_in? was false" if session_controller_debug_verbose
      # should have been redirected via mod_cosign - error out instead of going through redirect loop
      render(:status => :forbidden, :text => 'Forbidden')
    end
  end

  def logout_now
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
                                           "" ] if session_controller_debug_verbose
    sso_auto_logout
    redirect_to root_url unless session_controller_skip_redirect_on_logout
  end

end
