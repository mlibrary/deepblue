# frozen_string_literal: true
#
#hyrax5 - delete WillowSword

module WillowSword

  module IntegrationService

    mattr_accessor :skip_specs, default: true

    # mattr_accessor :willow_sword_integration_service_debug_verbose, default: false
    #
    # mattr_accessor :default_collection_title, default: WillowSword.config.default_collection_title
    # mattr_accessor :default_collection_id_cache, default: nil
    #
    # def self.default_collection_id
    #   collection_id = default_collection_id_cache
    #   return collection_id if collection_id.present?
    #   title = default_collection_title
    #   solr_query = "+generic_type_sim:Collection AND +title_tesim:#{title}"
    #   ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
    #                                          ::Deepblue::LoggingHelper.called_from,
    #                                          "title=#{title}",
    #                                          "solr_query=#{solr_query}",
    #                                          "" ] if willow_sword_integration_service_debug_verbose
    #   results = ::Hyrax::SolrService.query( solr_query, rows: 10 )
    #   ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
    #                                          ::Deepblue::LoggingHelper.called_from,
    #                                          "results.class.name=#{results.class.name}",
    #                                          "results=#{results}",
    #                                          "" ] if willow_sword_integration_service_debug_verbose
    #   if results.blank?
    #     ::Deepblue::LoggingHelper.bold_error [ ::Deepblue::LoggingHelper.here,
    #                                            ::Deepblue::LoggingHelper.called_from,
    #                                            "Error: Willow Sword default collection not found using title '#{default_collection_title}'",
    #                                            "" ]
    #   end
    #   collection_id = result.id if results.is_a? Collection
    #   collection_id = results[0].id unless collection_id.present?
    #   default_collection_id_cache = collection_id
    #   return collection_id
    # end

  end

end
