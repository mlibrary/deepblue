module Hyrax
  # This search builder requires that a accessor named "collection" exists in the scope
  class CollectionMemberSearchBuilder < ::SearchBuilder
    include Hyrax::FilterByType
    attr_reader :collection, :search_includes_models

    class_attribute :collection_membership_field
    self.collection_membership_field = 'member_of_collection_ids_ssim'

    # Defines which search_params_logic should be used when searching for Collection members
    self.default_processor_chain += [:member_of_collection]

    # @param [scope] Typically the controller object
    # @param [Symbol] :works, :collections, (anything else retrieves both)
    def initialize(scope:,
                   collection:,
                   search_includes_models: :works)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "scope=#{scope}",
                                             "collection.id=#{collection.id}",
                                             "search_includes_models=#{search_includes_models}",
                                             "" ]
      @collection = collection
      @search_includes_models = search_includes_models
      super(scope)
    end

    # include filters into the query to only include the collection memebers
    def member_of_collection(solr_parameters)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ]
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << "#{collection_membership_field}:#{collection.id}"
    end

    # This overrides the models in FilterByType
    def models
      rv = case search_includes_models
      when :collections
        collection_classes
      when :works
        work_classes
      else super # super includes both works and collections
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ]
      return rv
    end
  end
end
