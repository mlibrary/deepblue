# frozen_string_literal: true
# hyrax-orcid

module Hyrax
  module Orcid
    module UserBehavior
      extend ActiveSupport::Concern

      included do
        has_one :orcid_identity, dependent: :destroy

        mattr_accessor :hyrax_orcid_user_behavior_debug_verbose,
                       default: ::Hyrax::OrcidIntegrationService.hyrax_orcid_user_behavior_debug_verbose

        def orcid_identity_from_authorization(params)
          transformed = params.symbolize_keys
          transformed[:orcid_id] = transformed.delete(:orcid)

          create_orcid_identity(transformed)
        end

        def orcid_identity?
          orcid_identity.present?
        end

        # NOTE: I'm trying to avoid returning ID's and performing a Fedora query if I can help it,
        # but if we need to instantiate the Model objects, this can be done by returning just the ID
        # options = { fl: [:id], rows: 1_000_000 }
        def orcid_referenced_works
          debug_verbose = ::Hyrax::OrcidIntegrationService.hyrax_orcid_user_behavior_debug_verbose
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "orcid_identity=#{orcid_identity}",
                                                 "" ] if debug_verbose
          @_orcid_referenced_works ||= begin

            return [] if orcid_identity.blank?

            # We need to string concat here, so can't use single quotes (') around the query_string,
            # but solr requires that we use double quotes within the string or it will fail.
            query_string = "creator_orcid_tesim:\"#{orcid_identity.orcid_id}\" AND visibility_ssi:open"
            ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                   ::Deepblue::LoggingHelper.called_from,
                                                   "query_string=#{query_string}",
                                                   "" ] if debug_verbose
            result = ActiveFedora::SolrService.get(query_string, row: 1_000_000)
            ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                   ::Deepblue::LoggingHelper.called_from,
                                                   "result.size=#{result.size}",
                                                   "" ] if debug_verbose

            rv = result["response"]["docs"].map { |doc| ActiveFedora::SolrHit.new(doc) }
            ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                   ::Deepblue::LoggingHelper.called_from,
                                                   "rv=#{rv}",
                                                   "" ] if debug_verbose
            rv
          end
        end
      end
    end
  end
end
