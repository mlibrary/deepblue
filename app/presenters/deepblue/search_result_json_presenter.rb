# frozen_string_literal: true

module Deepblue

  class SearchResultJsonPresenter < ::Blacklight::JsonPresenter

    mattr_accessor :search_result_json_presenter_debug_verbose, default: false

    # @param [Solr::Response] response raw solr response.
    # @param [Array<SolrDocument>] documents a list of documents
    # @param [Array] facets list of facets
    def initialize( response, documents, facets, blacklight_config )
      super( response, documents, facets, blacklight_config )
    end

    def metadata_browse( doc )
      h = {}
      doc.model_property_names_browse.each do |name|
        solr_name = Solrizer.solr_name(name) # TODO: how to replace the Solrizer.solr_name(name)
        Rails.logger.debug "doc[#{name}]=#{doc[solr_name]}" if search_result_json_presenter_debug_verbose
        h[name] = doc[solr_name]
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "h=#{h}",
                                             "" ] if search_result_json_presenter_debug_verbose
      return h
    end

    def search_facets_as_json
      @facets.as_json.each do |f|
        facet_name = f["name"]
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "f=#{f}",
                                               "facet_name=#{facet_name}",
                                               "" ] if search_result_json_presenter_debug_verbose
        f.delete "options"
        facet_config = facet_configuration_for_field( facet_name )
        property_name = CatalogController.facet_solr_name_to_name( facet_name )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "facet_config=#{facet_config}",
                                               "property_name=#{property_name}",
                                               "" ] if search_result_json_presenter_debug_verbose
        f["name"] = property_name if property_name.present?
        # f["label"] = facet_config.label
        f["items"] = f["items"].as_json.each do |i|
          # i['label'] ||= i['value']
          i.remove['label'] if i.key('label')
        end
      end
    end

  end

end
