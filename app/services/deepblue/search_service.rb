# frozen_string_literal: true

module Deepblue

  # require_relative './search_service_managed_works'

  class SearchService

    mattr_accessor :search_service_debug_verbose, default: false

    include Blacklight::Base
    include Blacklight::AccessControls::Catalog

    copy_blacklight_config_from(::CatalogController)

    attr_reader :params, :user

    # @param [SolrDocument] item represents a work
    def self.run(params, user)
      new(params, user).list_works
    end

    def initialize(params, user)
      @params = params
      @user = user
    end

    def list_works
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params=#{params}",
                                             "user=#{user}",
                                             "" ] if search_service_debug_verbose
      rv = SearchServiceDepositorWorks.depositor_works_list(scope: self)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv.size=#{rv.size}",
                                             "" ] if search_service_debug_verbose
      return rv
    end

    def current_ability
      @current_ability ||= Ability.new(user)
    end

    def current_user
      @user
    end

    def repository
      config.repository
    end

    def config
      @config ||= ::CatalogController.new
    end

  end

end
