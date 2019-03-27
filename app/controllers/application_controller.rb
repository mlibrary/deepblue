# frozen_string_literal: true

class ApplicationController < ActionController::Base
  helper Openseadragon::OpenseadragonHelper
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  include Hydra::Controller::ControllerBehavior

  # Behavior for devise.  Use remote user field in http header for auth.
  include Devise::Behaviors::HttpHeaderAuthenticatableBehavior

  # Adds Hyrax behaviors into the application controller
  include Hyrax::Controller
  include Hyrax::ThemedLayoutController
  with_themed_layout '1_column'

  protect_from_forgery with: :exception

  if Rails.configuration.authentication_method == "umich"
    before_action :clear_session_user
  end

  # From PSU's ScholarSphere
  # Clears any user session and authorization information by:
  #   * forcing the session to be restarted on every request
  #   * ensuring the user will be logged out if REMOTE_USER is not set
  #   * clearing the entire session including flash messages
  def clear_session_user
    return nil_request if request.nil?
    search = session[:search].dup if session[:search]
    request.env['warden'].logout unless user_logged_in?
    session[:search] = search
  end
  
  def user_logged_in?
    user_signed_in? && ( valid_user?(request.headers) || Rails.env.test?)
  end

  def sso_logout
    redirect_to Hyrax::Engine.config.logout_prefix + logout_now_url
  end

  def sso_auto_logout
    Rails.logger.debug "[AUTHN] sso_auto_logout: #{current_user.try(:email) || '(no user)'}"
    sign_out(:user)
    cookies.delete("cosign-" + Hyrax::Engine.config.hostname, path: '/')
    session.destroy
    flash.clear
  end

  Warden::Manager.after_authentication do |user, auth, opts|
    Rails.logger.debug "[AUTHN] Warden after_authentication (clearing flash): #{user}"
    auth.request.flash.clear
  end

end
