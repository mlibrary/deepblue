# frozen_string_literal: true
# hyrax-orcid

module Hyrax
  module Orcid
    module Profile
      class EmploymentPresenter < BasePresenter
        def key
          "employment"
        end

        def collection
          debug_verbose = ::Hyrax::OrcidIntegrationService.hyrax_orcid_presenter_debug_verbose
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "@collection=#{@collection}",
                                                 "" ] if debug_verbose
          rv = @collection.map do |entry|
            ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                   ::Deepblue::LoggingHelper.called_from,
                                                   "entry=#{entry}",
                                                   "" ] if debug_verbose
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
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "rv=#{rv}",
                                                 "" ] if debug_verbose
          return rv
        end
      end
    end
  end
end
