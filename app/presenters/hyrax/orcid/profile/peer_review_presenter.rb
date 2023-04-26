# frozen_string_literal: true
# hyrax-orcid

module Hyrax
  module Orcid
    module Profile
      class PeerReviewPresenter < BasePresenter
        def key
          "peer_reviews"
        end

        def collection
          @collection.map do |col|
            entry = col["peer-review-summary"].first

            {
              title: entry.dig("title", "title", "value"),
              items: [
                entry.dig('convening-organization', 'name'),
                date_from_hash(entry['completion-date']),
                linkify_external_ids(entry)
              ].reject(&:blank?)
            }
          end
        end
      end
    end
  end
end
