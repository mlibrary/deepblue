# frozen_string_literal: true
# Reviewed: hyrax4

# monkey patch

module Hyrax

  # This search builder requires that a accessor named "collection" exists in the scope
  class CollectionMemberSearchBuilder < ::SearchBuilder
    # begin monkey
    mattr_accessor :collection_member_search_builder_debug_verbose, default: false
    # end monkey

    include Hyrax::FilterByType
    attr_writer :collection, :search_includes_models

    class_attribute :collection_membership_field
    self.collection_membership_field = 'member_of_collection_ids_ssim'

    # Defines which search_params_logic should be used when searching for Collection members
    self.default_processor_chain += [:member_of_collection]

    # @param [Object] scope Typically the controller object
    # @param [Symbol] search_includes_models +:works+ or +:collections+; (anything else retrieves both)
    def initialize(*args,
                   scope: nil,
                   collection: nil,
                   search_includes_models: nil)
    # begin monkey
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "scope=#{scope}",
                                             "collection.id=#{collection.id}",
                                             "search_includes_models=#{search_includes_models}",
                                             "" ] if collection_member_search_builder_debug_verbose
    # end monkey
    @collection = collection
      @search_includes_models = search_includes_models

      if args.any?
        super(*args)
      else
        super(scope)
      end
    end

    def collection
      @collection || (scope.context[:collection] if scope&.respond_to?(:context))
    end

    def search_includes_models
      @search_includes_models || :works
    end

    # include filters into the query to only include the collection memebers
    def member_of_collection(solr_parameters)
      # begin monkey
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if collection_member_search_builder_debug_verbose
      # begin monkey
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << "#{collection_membership_field}:#{collection.id}"
    end

    # This overrides the models in FilterByType
    def models
      work_classes + collection_classes
    end

    # This overrides the models in FilterByType
    def models_v2
      rv = case search_includes_models
      when :collections
        collection_classes
      when :works
        work_classes
      else super # super includes both works and collections
      end
      # begin monkey
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ] if collection_member_search_builder_debug_verbose
      # begin monkey
      return rv
    end

    def only_works?
      search_includes_models == :works
    end

    def only_collections?
      search_includes_models == :collections
    end

  end
end
