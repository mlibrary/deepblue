module Hyrax

  # Our parent class is the generated SearchBuilder descending from Blacklight::SearchBuilder
  # It includes Blacklight::Solr::SearchBuilderBehavior, Hydra::AccessControlsEnforcement, Hyrax::SearchFilters
  # @see https://github.com/projectblacklight/blacklight/blob/master/lib/blacklight/search_builder.rb Blacklight::SearchBuilder parent
  # @see https://github.com/projectblacklight/blacklight/blob/master/lib/blacklight/solr/search_builder_behavior.rb Blacklight::Solr::SearchBuilderBehavior
  # @see https://github.com/samvera/hyrax/blob/master/app/search_builders/hyrax/README.md SearchBuilders README
  # @note the default_processor_chain defined by Blacklight::Solr::SearchBuilderBehavior provides many possible points of override
  #
  # Allows :deposit as a valid type
  class CollectionSearchBuilder < ::SearchBuilder

    COLLECTION_SEARCH_BUILDER_DEBUG_VERBOSE = false

    include FilterByType

    attr_reader :access

    # Overrides Hydra::AccessControlsEnforcement
    def discovery_permissions
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "" ] if COLLECTION_SEARCH_BUILDER_DEBUG_VERBOSE
      @discovery_permissions = extract_discovery_permissions(@access)
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "@discovery_permissions=#{@discovery_permissions}",
                                             "" ] if COLLECTION_SEARCH_BUILDER_DEBUG_VERBOSE
      @discovery_permissions
    end

    # @return [String] Solr field name indicating default sort order
    def sort_field
      'title_si'
    end

    # This overrides the models in FilterByType
    def models
      # To make sure that both collections and adminsets are 
      # sortable in the All collections tab of the dashboard.
      [AdminSet, Collection]
    end

    def with_access(access)
      @access = access
      super(access)
    end

    # If no sort parameter is passed, it will sort
    # by relevance.
    def add_sorting_to_solr(solr_parameters)
      solr_parameters[:sort] = sort unless sort.blank?
    end

    # If :deposit access is requested, check to see which collections the user has
    # deposit or manage access to.
    # @return [Array<String>] a list of filters to apply to the solr query
    def gated_discovery_filters(permission_types = discovery_permissions, ability = current_ability)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "ability.admin?=#{ability.admin?}",
                                             "" ] if COLLECTION_SEARCH_BUILDER_DEBUG_VERBOSE
      # return [] if ability.admin?
      permissions = permission_types.include?("deposit")
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "permission_types.include?(\"deposit\")=#{permissions}",
                                             "" ] if COLLECTION_SEARCH_BUILDER_DEBUG_VERBOSE
      rv = super unless permissions
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "super=#{rv}",
                                             "" ] if COLLECTION_SEARCH_BUILDER_DEBUG_VERBOSE
      return rv unless permissions
      rv = ["{!terms f=id}#{collection_ids_for_deposit.join(',')}"]
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ] if COLLECTION_SEARCH_BUILDER_DEBUG_VERBOSE
      return rv
    end

    private

      def collection_ids_for_deposit
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "" ] if COLLECTION_SEARCH_BUILDER_DEBUG_VERBOSE
        rv = Hyrax::Collections::PermissionsService.collection_ids_for_deposit(ability: current_ability)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "rv=#{rv}",
                                               "" ] if COLLECTION_SEARCH_BUILDER_DEBUG_VERBOSE
        return rv
      end

      ACCESS_LEVELS_FOR_LEVEL = ActiveSupport::HashWithIndifferentAccess.new(
        edit: ["edit"],
        deposit: ["deposit"],
        read: ["edit", "read"]
      ).freeze

      def extract_discovery_permissions(access)
        access = :read if access.blank?
        ACCESS_LEVELS_FOR_LEVEL.fetch(access)
      end

  end

end
