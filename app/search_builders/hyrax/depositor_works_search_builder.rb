
module Hyrax

  class DepositorWorksSearchBuilder < Hyrax::WorksSearchBuilder
    include Hyrax::Dashboard::ManagedSearchFilters

    self.default_processor_chain += [:show_only_managed_works_for_non_admins]
    self.default_processor_chain -= [:only_active_works, :add_access_controls_to_solr_params]

    # Adds a filter to exclude works created by the current user.
    # @param [Hash] solr_parameters
    def show_only_managed_works_for_non_admins(solr_parameters)
      solr_parameters[:fq] ||= []
      # solr_parameters[:fq] << '-' + ActiveFedora::SolrQueryBuilder.construct_query_for_rel(depositor: current_user_key)
      solr_parameters[:fq] << ActiveFedora::SolrQueryBuilder.construct_query_for_rel(depositor: current_user_key)
    end

  end

end
