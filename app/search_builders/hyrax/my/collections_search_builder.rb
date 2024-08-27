# frozen_string_literal: true
# Reviewed: hyrax4

# monkey override

# Added to allow for the My controller to show only things I have edit access to
class Hyrax::My::CollectionsSearchBuilder < ::Hyrax::CollectionSearchBuilder
  include Hyrax::My::SearchBuilderBehavior
  include Hyrax::FilterByType

  self.default_processor_chain += [:show_only_collections_deposited_by_current_user]

  # adds a filter to the solr_parameters that filters the collections and admin sets
  # the current user has deposited
  # @param [Hash] solr_parameters
  def show_only_collections_deposited_by_current_user(solr_parameters)
    clauses = [
      ActiveFedora::SolrQueryBuilder.construct_query_for_rel(depositor: current_user_key),
      ActiveFedora::SolrQueryBuilder.construct_query_for_rel(has_model: ::AdminSet.to_s, creator: current_user_key)
    ]
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] += ["(#{clauses.join(' OR ')})"]
  end

  # This overrides the models in FilterByType
  # @return [Array<Class>] a list of classes to include
  def models
    [::AdminSet, ::Collection]
  end

  private

  def query_for_my_collections
    query_service = Hyrax::SolrQueryService.new
    query_service.with_field_pairs(field_pairs: { depositor_ssim: current_user_key }, type: 'terms')
    query_service.with_field_pairs(field_pairs: { has_model_ssim: Hyrax.config.admin_set_model,
                                                  creator_ssim: current_user_key }, type: 'terms')
    query_service.build(join_with: 'OR')
  end
end
