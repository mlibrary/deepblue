# frozen_string_literal: true
# hyrax-orcid

module Hyrax
  module Orcid
    module Profile
      class FundingPresenter < BasePresenter
        def key
          "funding"
        end

        def collection
          debug_verbose = ::Hyrax::OrcidIntegrationService.hyrax_orcid_presenter_debug_verbose
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "@collection=#{@collection}",
                                                 "" ] if debug_verbose
          @collection.map do |col|
            entry = col["funding-summary"].first

            {
              title: entry.dig("title", "title", "value"),
              items: [
                "#{entry.dig('organization', 'name')} (#{entry.dig('organization', 'address', 'city')})",
                "#{date_from_hash(entry['start-date'])} - #{date_from_hash(entry['end-date'])} | #{entry.dig('type')}",
                grant(entry),
                url(entry)
              ].reject(&:blank?)
            }
          end
        end

        protected

          def grant(entry)
            ids = external_ids(entry)

            "#{ids.dig('external-id-type').humanize}: #{ids.dig('external-id-value')}"
          end

          def url(entry)
            url = external_ids(entry).dig('external-id-url', 'value')

            "URL: #{h.link_to url, url}"
          end
      end
    end
  end
end
