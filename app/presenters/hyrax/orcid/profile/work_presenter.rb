# frozen_string_literal: true
# hyrax-orcid

module Hyrax
  module Orcid
    module Profile
      class WorkPresenter < BasePresenter
        def key
          "works"
        end

        # rubocop:disable Metrics/MethodLength
        def collection
          debug_verbose = ::Hyrax::OrcidIntegrationService.hyrax_orcid_presenter_debug_verbose
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "@collection=#{@collection}",
                                                 "" ] if debug_verbose
          @collection.map do |col|
            entry = col["work"]

            hsh = {
              title: entry.dig("title", "title", "value"),
              items: [
                date_from_hash(entry['completion-date']),
                linkify_external_ids(entry)
              ].reject(&:blank?)
            }

            if (contributors = contributors(entry)).present?
              hsh[:items].unshift("Contributor(s): #{contributors}")
            end

            if (creators = creators(entry)).present?
              hsh[:items].unshift("Author(s): #{creators}")
            end

            hsh
          end
        end
        # rubocop:enable Metrics/MethodLength

        protected

          def creators(entry)
            grouped_contributors(entry)
              .then { |hsh| hsh.dig("AUTHOR") }
              .then { |hsh| link_contributors(hsh) }
              .then { |ary| ary.compact.join(", ") }
          end

          def contributors(entry)
            grouped_contributors(entry)
              .then { |hsh| hsh.except("AUTHOR") }
              .then { |hsh| hsh.values.first }
              .then { |hsh| link_contributors(hsh) }
              .then { |ary| Array.wrap(ary).join(", ") }
          end

          def grouped_contributors(entry)
            entry.dig("contributors", "contributor").group_by { |c| c.dig("contributor-attributes", "contributor-role") }
          end

          def link_contributors(hsh)
            return if hsh.blank?

            hsh.map do |contributor|
              url = contributor.dig("contributor-orcid", "uri")
              text = contributor.dig("credit-name", "value")

              h.link_to_if url, text, url
            end
          end
      end
    end
  end
end
