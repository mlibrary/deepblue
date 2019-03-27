# frozen_string_literal: true

# this class is specific to UMich authentication only
class SessionsController < ApplicationController

  def destroy
    if user_signed_in?
      sso_logout
    else
      logout_now
    end
  end

  def new
    raise unless Rails.configuration.authentication_method == "umich"
    if user_signed_in?
      Rails.logger.debug "[AUTHN] sessions#new, redirecting"
      # redirect to where user came from (see Devise::Controllers::StoreLocation#stored_location_for)
      redirect_to stored_location_for(:user) || hyrax.dashboard_path
    else
      Rails.logger.debug "[AUTHN] sessions#new, failed because user_signed_in? was false"
      # should have been redirected via mod_cosign - error out instead of going through redirect loop
      render(:status => :forbidden, :text => 'Forbidden')
    end
  end

  def logout_now
    sso_auto_logout
    redirect_to root_url
  end

end
