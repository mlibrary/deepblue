# frozen_string_literal: true
# hyrax-orcid

module Hyrax
  module Orcid
    module UserBehavior
      extend ActiveSupport::Concern

      included do
        has_one :orcid_identity, dependent: :destroy

        def orcid_identity_from(hash)
          begin
            create_orcid_identity(hash)
          rescue Exception => e
            ::Deepblue::LoggingHelper.bold_error [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
                                                   "hash=#{hash.pretty_inspect}",
                                                   "e=#{e}",
                                                   "" ] + e.backtrace
          end
        end

        def orcid_identity_from_authorization(params)
          transformed = params.symbolize_keys
          transformed[:orcid_id] = transformed.delete(:orcid)
          orcid_identity_from(transformed)
        end

        def orcid_identity?
          orcid_identity.present?
        end

        # NOTE: I'm trying to avoid returning ID's and performing a Fedora query if I can help it,
        # but if we need to instantiate the Model objects, this can be done by returning just the ID
        # options = { fl: [:id], rows: 1_000_000 }
        def orcid_referenced_works
          @_orcid_referenced_works ||= begin

            return [] if orcid_identity.blank?

            # We need to string concat here, so can't use single quotes (') around the query_string,
            # but solr requires that we use double quotes within the string or it will fail.
            query_string = "creator_orcid_tesim:\"#{orcid_identity.orcid_id}\" AND visibility_ssi:open"
            result = ActiveFedora::SolrService.get(query_string, row: 1_000_000)

            rv = result["response"]["docs"].map { |doc| ActiveFedora::SolrHit.new(doc) }
            rv
          end
        end
      end
    end
  end
end
