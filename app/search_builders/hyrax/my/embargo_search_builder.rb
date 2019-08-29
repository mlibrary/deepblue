# frozen_string_literal: true

module Hyrax

  module My

    # Finds embargoed objects owned by current user
    class EmbargoSearchBuilder < Blacklight::SearchBuilder
      self.default_processor_chain = [:with_pagination, :with_sorting, :only_active_embargoes, :show_only_resources_deposited_by_current_user ]

      attr_accessor :current_user_key

      # TODO: add more complex pagination
      def with_pagination(solr_params)
        solr_params[:rows] = 1000
      end

      def with_sorting(solr_params)
        solr_params[:sort] = 'embargo_release_date_dtsi desc'
      end

      def only_active_embargoes(solr_params)
        solr_params[:fq] ||= []
        solr_params[:fq] += [ 'embargo_release_date_dtsi:*' ]
      end

      # adds a filter to the solr_parameters that filters the documents the current user
      # has deposited
      # @param [Hash] solr_parameters
      def show_only_resources_deposited_by_current_user(solr_parameters)
        solr_parameters[:fq] ||= []
        solr_parameters[:fq] += [
            ActiveFedora::SolrQueryBuilder.construct_query_for_rel(depositor: current_user_key)
        ]
      end

    end

  end

end
