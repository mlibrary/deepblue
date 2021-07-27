# frozen_string_literal: true

class ApplicationController < ActionController::Base

  mattr_accessor :application_controller_debug_verbose,
                 default: ::DeepBlueDocs::Application.config.application_controller_debug_verbose

  helper Openseadragon::OpenseadragonHelper
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  skip_after_action :discard_flash_if_xhr
  include Hydra::Controller::ControllerBehavior

  # Behavior for devise.  Use remote user field in http header for auth.
  include Devise::Behaviors::HttpHeaderAuthenticatableBehavior

  # Adds Hyrax behaviors into the application controller
  include Hyrax::Controller
  include Hyrax::ThemedLayoutController
  with_themed_layout '1_column'

  after_action :track_action

  def track_action
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if ::Deepblue::AnalyticsIntegrationService.event_tracking_debug_verbose
    # ahoy.track self.class.name, request.path_parameters
    # ahoy.track "#{controller_name}##{action_name}", request.filtered_parameters
    properties = request.filtered_parameters.dup
    properties[:url] = request.url if ::Deepblue::AnalyticsIntegrationService.event_tracking_include_request_uri
    ::Deepblue::AnalyticsIntegrationService.event_tracking_excluded_parameters.each do |excluded|
      properties.delete excluded
    end
    track_action_update_parms!( properties: properties )
    # ahoy.track("#{self.class.name}##{action_name}", properties )
    cc_id = tracking_cc_id
    ahoy.track_with_id("#{self.class.name}##{action_name}", cc_id,  properties )
  end

  # override this as necessary to add or delete tracked parameters
  def track_action_update_parms!( properties: )
    # override this as necessary to add or delete tracked parameters
  end

  def tracking_cc_id
    return params[:id] if params.has_key? :id
    return nil unless respond_to? :id
    id
  end

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
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "[AUTHN] clear_session_user: #{current_user.try(:email) || '(no user)'}",
                                           "request=#{request}",
                                           # "request&.keys=#{request&.keys}",
                                           "session=#{session}",
                                           "session&.keys=#{session&.keys}",
                                           "params=#{params}",
                                           "params.keys=#{params.keys}",
                                           "" ] if application_controller_debug_verbose
    return nil_request if request.nil?
    # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
    #                                        ::Deepblue::LoggingHelper.called_from,
    #                                        "[AUTHN] clear_session_user: #{current_user.try(:email) || '(no user)'} request not nil",
    #                                        "params=#{params}",
    #                                        "" ] if application_controller_debug_verbose
    search = session[:search].dup if session[:search]
    flash = session[:flash].dup if session[:flash]
    request.env['warden'].logout unless single_use_link_request? || user_logged_in?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "[AUTHN] clear_session_user: #{current_user.try(:email) || '(no user)'}",
                                           "After: request.env['warden'].logout unless user_logged_in?",
                                           "request=#{request}",
                                           # "request&.keys=#{request&.keys}",
                                           "session=#{session}",
                                           "session&.keys=#{session&.keys}",
                                           "params=#{params}",
                                           "params.keys=#{params.keys}",
                                           "" ] if application_controller_debug_verbose
    session[:search] = search if search
    session[:flash] = flash if flash
    # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
    #                                        ::Deepblue::LoggingHelper.called_from,
    #                                        "[AUTHN] clear_session_user: #{current_user.try(:email) || '(no user)'}",
    #                                        "After: session search and flash restored",
    #                                        "request=#{request}",
    #                                        # "request&.keys=#{request&.keys}",
    #                                        "session=#{session}",
    #                                        "session&.keys=#{session&.keys}",
    #                                        "params=#{params}",
    #                                        "params.keys=#{params.keys}",
    #                                        "" ] if application_controller_debug_verbose
  end
  
  def user_logged_in?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if application_controller_debug_verbose
    user_signed_in? && ( valid_user?(request.headers) || Rails.env.test?)
  end

  # override this as necessary to support single_use_link requests
  def anonymous_link_request?
    return false
  end

  # override this as necessary to support single_use_link requests
  def single_use_link_request?
    return false
  end

  def sso_logout
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "[AUTHN] sso_logout: #{current_user.try(:email) || '(no user)'}",
                                           "" ] if application_controller_debug_verbose
    redirect_to Hyrax::Engine.config.logout_prefix + logout_now_url
  end

  def sso_auto_logout
    # Rails.logger.debug "[AUTHN] sso_auto_logout: #{current_user.try(:email) || '(no user)'}" if application_controller_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "[AUTHN] sso_auto_logout: #{current_user.try(:email) || '(no user)'}",
                                           "" ] if application_controller_debug_verbose
    sign_out(:user)
    cookies.delete("cosign-" + Hyrax::Engine.config.hostname, path: '/')
    session.destroy
    flash.clear
  end

  Warden::Manager.after_authentication do |user, auth, opts|
    # Rails.logger.debug "[AUTHN] Warden after_authentication (clearing flash): #{user}" if application_controller_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "[AUTHN] Warden after_authentication (clearing flash): #{user}",
                                           "" ] if application_controller_debug_verbose
    auth.request.flash.clear
  end

end
