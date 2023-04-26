# frozen_string_literal: true
# hyrax-orcid

module Hyrax
  module Orcid
    module Profile
      class BasePresenter
        def initialize(collection)
          @collection = collection
        end

        def key
          raise NotImplementedError, "A key slug must be provided"
        end

        def collection
          raise NotImplementedError, "A collection method is required to return a hash"
        end

        protected

          # Format: {"year"=>{"value"=>"1997"}, "month"=>{"value"=>"08"}, "day"=>{"value"=>"20"}}
          def date_from_hash(hsh, format = "%Y-%m-%d")
            return if hsh.blank?

            Date.new(*hsh.map { |_k, v| v["value"].to_i }).strftime(format)
          end

          # Format: {"city"=>"Cambridge", "region"=>"MA", "country"=>"US"}
          def address_from_hash(hash)
            hash.values.join(", ")
          end

          def linkify_external_ids(entry)
            ids = external_ids(entry)
            url = ids.dig("external-id-url", "value")

            link = h.link_to_if url, ids["external-id-value"], url

            "#{ids['external-id-type'].underscore.humanize}: #{link}"
          end

          def external_ids(entry)
            entry.dig("external-ids", "external-id").first
          end

          def h
            ActionController::Base.helpers
          end
      end
    end
  end
end
