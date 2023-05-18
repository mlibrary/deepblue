# frozen_string_literal: true
# hyrax-orcid

module Hyrax
  module Orcid
    module Profile
      class EducationPresenter < BasePresenter
        def key
          "education"
        end

        def collection
          debug_verbose = ::Hyrax::OrcidIntegrationService.hyrax_orcid_presenter_debug_verbose
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "@collection=#{@collection}",
                                                 "" ] if debug_verbose
          @collection.map do |entry|
            {
              title: entry["role-title"],
              items: [
                "#{date_from_hash(entry['start-date'])} - #{date_from_hash(entry['end-date'])}",
                entry["department-name"],
                entry.dig("organization", "name"),
                address_from_hash(entry.dig("organization", "address"))
              ].reject(&:blank?)
            }
          end
        end
      end
    end
  end
end
