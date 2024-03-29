# frozen_string_literal: true

require File.expand_path('../helpers/browse_everything_helper', __dir__)

class BrowseEverythingController < ApplicationController

  # begin monkey
  mattr_accessor :browse_everything_controller_debug_verbose,
                 default: ::BrowseEverythingIntegrationService.browse_everything_controller_debug_verbose
  mattr_accessor :browse_everything_controller2_debug_verbose,
                 default: ::BrowseEverythingIntegrationService.browse_everything_controller2_debug_verbose
  # end monkey

  layout 'browse_everything'
  helper BrowseEverythingHelper

  protect_from_forgery with: :exception

  before_action do
    # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
    #                                        ::Deepblue::LoggingHelper.called_from,
    #                                        "" ] if true
  end

  after_action do
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if browse_everything_controller2_debug_verbose
    provider_session.token = provider.token unless provider.nil? || provider.token.blank?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "provider_session.token = #{provider_session.token}",
                                           "" ] if browse_everything_controller2_debug_verbose
    provider_session.token
  end

  def provider_contents
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "provider=#{provider}",
                                           "provider.class.name=#{provider.class.name}",
                                           "" ] if browse_everything_controller_debug_verbose
    raise BrowseEverything::NotImplementedError, 'No provider supported' if provider.nil?
    raise BrowseEverything::NotAuthorizedError, 'Not authorized' unless provider.authorized?

    rv = provider.contents(browse_path)
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "provider.contents(browse_path) = #{rv}",
                                           "" ] if browse_everything_controller2_debug_verbose
    rv
  end

  def index
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if browse_everything_controller_debug_verbose
    render layout: !request.xhr?
  end

  # Either render the link to authorization or render the files
  # provider#show method is invoked here
  def show
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "" ] if browse_everything_controller_debug_verbose
    render partial: 'files', layout: !request.xhr?
  rescue StandardError => e
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "error=#{e}",
                                           "" ] if browse_everything_controller2_debug_verbose
    Rails.logger.error "#{e.class} -- #{e.message} at #{e.backtrace[0]}"
    ::Deepblue::LoggingHelper.bold_error [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "ERROR",
                                           "e=#{e.class.name}",
                                           "e.message=#{e.message}",
                                           "e.backtrace:" ] + e.backtrace # error
    reset_provider_session!

    # Should an error be raised, log the error and redirect the use to reauthenticate
    logger.warn "Failed to retrieve the hosted files: #{e}"
    render partial: 'auth', layout: !request.xhr?
  end

  # Action for the OAuth2 callback
  # Authenticate against the API and store the token in the session
  def auth
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "" ] if browse_everything_controller_debug_verbose
    # params contains the access code with with the key :code
    provider_session.token = provider.connect(params, provider_session.data, connector_response_url_options)
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "provider_session.token=#{provider_session.token}",
                                           "" ] if browse_everything_controller_debug_verbose
    provider_session.token
  end

  def resolve
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "" ] if browse_everything_controller_debug_verbose
    selected_files = params[:selected_files] || []
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "selected_files=#{selected_files}",
                                           "" ] if browse_everything_controller_debug_verbose
    selected_links = selected_files.collect do |file|
      provider_key_value, uri = file.split(/:/)
      provider_key = provider_key_value.to_sym
      (url, extra) = browser.providers[provider_key].link_for(uri)
      result = { url: url }
      result.merge!(extra) unless extra.nil?
      result
    end
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "selected_links=#{selected_links}",
                                           "" ] if browse_everything_controller_debug_verbose

    respond_to do |format|
      format.html { render layout: false }
      format.json { render json: selected_links }
    end
  end

  private

  # Constructs or accesses an existing session manager Object
  # @return [BrowseEverythingSession::ProviderSession] the session manager
  def provider_session
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if browse_everything_controller2_debug_verbose
    sess = session
    prov_name = provider_name
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "session=#{sess}",
                                           "provider_name=#{prov_name}",
                                           "" ] if browse_everything_controller2_debug_verbose
    rv = BrowseEverythingSession::ProviderSession.new(session: sess, name: prov_name)
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "session=#{rv}",
                                            "" ] if browse_everything_controller2_debug_verbose
    return rv
  end

  # Clears all authentication tokens, codes, and other data from the Rails session
  def reset_provider_session!
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if browse_everything_controller2_debug_verbose
    return unless @provider_session
    @provider_session.token = nil
    @provider_session.code = nil
    @provider_session.data = nil
    @provider_session = nil
  end

  def connector_response_url_options
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "protocol: #{request.protocol}",
                                           "host: #{request.host}",
                                           "port: #{request.port}",
                                           "" ] if browse_everything_controller_debug_verbose
    rv = { protocol: request.protocol, host: request.host, port: request.port }
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "connector_response_url_options rv=#{rv}",
                                           "" ] if browse_everything_controller2_debug_verbose
    rv
  end

  # Generates the authentication link for a given provider service
  # @return [String] the authentication link
  def auth_link
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "provider=#{provider}",
                                           "" ] if browse_everything_controller_debug_verbose
    @auth_link ||= if provider.present?
                     ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                            ::Deepblue::LoggingHelper.called_from,
                                                            "" ] if browse_everything_controller_debug_verbose
                     link, data = provider.auth_link(connector_response_url_options)
                     ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                            ::Deepblue::LoggingHelper.called_from,
                                                            "link=#{link}",
                                                            "data=#{data}",
                                                            "" ] if browse_everything_controller_debug_verbose
                     provider_session.data = data
                     link = "#{link}&state=#{provider.key}" unless link.to_s.include?('state')
                     link
                   end
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@auth_link = #{@auth_link}",
                                           "" ] if browse_everything_controller2_debug_verbose
    @auth_link
  end

  # Accesses the relative path for browsing from the Rails session
  # @return [String]
  def browse_path
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if browse_everything_controller2_debug_verbose
    rv = params[:path] || ''
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "browse_path rv=#{rv}",
                                           "" ] if browse_everything_controller2_debug_verbose
    rv
  end

  # Generate the provider name from the Rails session state value
  # @return [String]
  def provider_name_from_state
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if browse_everything_controller2_debug_verbose
    rv = params[:state].to_s.split(/\|/).last
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "provider name_from_stat rv=#{rv}",
                                           "" ] if browse_everything_controller2_debug_verbose
    rv
  end

  # Generates the name of the provider using Rails session values
  # @return [String]
  def provider_name
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if browse_everything_controller2_debug_verbose
    rv = params[:provider] || provider_name_from_state || browser.providers.each_key.to_a.first
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "provider_name rv=#{rv}",
                                           "" ] if browse_everything_controller2_debug_verbose
    rv
  end

  # Retrieve the Driver for each request
  # @return [BrowseEverything::Driver::Base]
  def provider
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if browse_everything_controller2_debug_verbose
    prov_name = provider_name
    rv = browser.providers[prov_name.to_sym] if prov_name.present?
    rv ||= browser.first_provider
    # browser.providers[provider_name.to_sym] || browser.first_provider
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "provider=#{rv}",
                                           "" ] if browse_everything_controller2_debug_verbose
    rv
  end

  # Constructs a browser manager Object
  # Browser state cannot persist between requests to the Controller
  # Hence, a Browser must be reinstantiated for each request using the state provided in the Rails session
  # @return [BrowseEverything::Browser]
  def browser
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if browse_everything_controller2_debug_verbose
    rv = BrowserFactory.build(session: session, url_options: url_options)
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "rv = #{rv}",
                                           "" ] if browse_everything_controller2_debug_verbose
    rv
  end

  helper_method :auth_link
  helper_method :browser
  helper_method :browse_path
  helper_method :provider
  helper_method :provider_name
  helper_method :provider_contents
end
