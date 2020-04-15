# frozen_string_literal: true
module Deepblue

  class SearchResultJsonPresenter < ::Blacklight::JsonPresenter

    SEARCH_RESULT_JSON_PRESENTER_DEBUG_VERBOSE = false

    # @param [Solr::Response] response raw solr response.
    # @param [Array<SolrDocument>] documents a list of documents
    # @param [Array] facets list of facets
    def initialize( response, documents, facets, blacklight_config )
      super( response, documents, facets, blacklight_config )
    end

    def metadata_browse( doc )
      h = {}
      doc.model_property_names_browse.each do |name|
        solr_name = Solrizer.solr_name(name)
        Rails.logger.debug "doc[#{name}]=#{doc[solr_name]}" if SEARCH_RESULT_JSON_PRESENTER_DEBUG_VERBOSE
        h[name] = doc[solr_name]
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "h=#{h}",
                                             "" ] if SEARCH_RESULT_JSON_PRESENTER_DEBUG_VERBOSE
      return h
    end

  end

end
