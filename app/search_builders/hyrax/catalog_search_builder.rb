
class Hyrax::CatalogSearchBuilder < Hyrax::SearchBuilder

  mattr_accessor :catalog_search_builder_debug_verbose, default: false

  self.default_processor_chain += [
    :add_access_controls_to_solr_params,
    :show_works_or_works_that_contain_files,
    :show_only_active_records,
    :filter_collection_facet_for_access,
    :remove_draft_works
  ]

  # show both works that match the query and works that contain files that match the query
  def show_works_or_works_that_contain_files(solr_parameters)
    # begin monkey
    ::Deepblue::LoggingHelper.bold_debug [::Deepblue::LoggingHelper.here,
                                          ::Deepblue::LoggingHelper.called_from,
                                          "solr_parameters.inspect=#{solr_parameters.inspect}",
                                          ""] if catalog_search_builder_debug_verbose
    # end monkey
    return if blacklight_params[:q].blank? || blacklight_params[:search_field] != 'all_fields'
    solr_parameters[:user_query] = blacklight_params[:q]
    solr_parameters[:q] = new_query
    solr_parameters[:defType] = 'lucene'
    # begin monkey
    ::Deepblue::LoggingHelper.bold_debug [::Deepblue::LoggingHelper.here,
                                          ::Deepblue::LoggingHelper.called_from,
                                          "solr_parameters.inspect=#{solr_parameters.inspect}",
                                          ""] if catalog_search_builder_debug_verbose
    # end monkey
  end

  # show works that are in the active state.
  def show_only_active_records(solr_parameters)
    # begin monkey
    ::Deepblue::LoggingHelper.bold_debug [::Deepblue::LoggingHelper.here,
                                          ::Deepblue::LoggingHelper.called_from,
                                          "solr_parameters.inspect=#{solr_parameters.inspect}",
                                          ""] if catalog_search_builder_debug_verbose
    # end monkey
    solr_parameters[:fq] ||= []
    return if current_ability.admin? # this allows all works to show up in browse for admins
    solr_parameters[:fq] << '-suppressed_bsi:true'
    # begin monkey
    ::Deepblue::LoggingHelper.bold_debug [Deepblue::LoggingHelper.here,
                                          Deepblue::LoggingHelper.called_from,
                                          "solr_parameters.inspect=#{solr_parameters.inspect}",
                                          ""] if catalog_search_builder_debug_verbose
    # end monkey
  end

  # only return facet counts for collections that this user has access to see
  def filter_collection_facet_for_access(solr_parameters)
    # begin monkey
    ::Deepblue::LoggingHelper.bold_debug [Deepblue::LoggingHelper.here,
                                          Deepblue::LoggingHelper.called_from,
                                          "solr_parameters.inspect=#{solr_parameters.inspect}",
                                          ""] if catalog_search_builder_debug_verbose
    # end monkey
    return if current_ability.admin?

    collection_ids = Hyrax::Collections::PermissionsService.collection_ids_for_view(ability: current_ability).map { |id| "^#{id}$" }
    solr_parameters['f.member_of_collection_ids_ssim.facet.matches'] = if collection_ids.present?
                                                                         collection_ids.join('|')
                                                                       else
                                                                         "^$"
                                                                       end
    # begin monkey
    ::Deepblue::LoggingHelper.bold_debug [Deepblue::LoggingHelper.here,
                                          Deepblue::LoggingHelper.called_from,
                                          "solr_parameters.inspect=#{solr_parameters.inspect}",
                                          ""] if catalog_search_builder_debug_verbose
    # end monkey
  end

  private

    # the {!lucene} gives us the OR syntax
    def new_query
      "{!lucene}#{interal_query(dismax_query)} #{interal_query(join_for_works_from_files)}"
    end

    # the _query_ allows for another parser (aka dismax)
    def interal_query(query_value)
      "_query_:\"#{query_value}\""
    end

    # the {!dismax} causes the query to go against the query fields
    def dismax_query
      "{!dismax v=$user_query}"
    end

    # join from file id to work relationship solrized file_set_ids_ssim
    def join_for_works_from_files
      "{!join from=#{ActiveFedora.id_field} to=file_set_ids_ssim}#{dismax_query}"
    end
end
