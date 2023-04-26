# frozen_string_literal: true
# hyrax-orcid

# Methods which attemt to normalize writing (ouputting) data from the parsed Bolognese Meta readers, and allow them
# to be used in a number of different areas, all of which must extend or be prepended into Bolognese::Metadata

# rubocop:disable Metrics/ModuleLength
module Bolognese
  module Helpers
    module Writers
      extend ActiveSupport::Concern

      def write_doi
        Array(doi)
      end

      def write_uuid
        meta["uuid"]
      end

      def write_title
        titles&.pluck("title")
      end

      def write_alt_title
        meta.dig("alt_title")
      end

      def write_creator
        write_participants("creators")
      end

      def write_contributor
        write_participants("contributors")
      end

      def write_editor
        write_participants("contributors").select { |cont| cont["contributor_contributor_type"] == "Editor" }
      end

      def write_publisher
        Array(publisher)
      end

      def write_keyword
        subjects&.pluck("subject")
      end

      def write_language
        Array(language)
      end

      def write_issn
        [identifier_by_type(:container, "ISSN")].compact
      end

      def write_isbn
        [identifier_by_type(:identifiers, "ISBN")].compact
      end

      def write_license
        urls = rights_list&.pluck("rightsUri")&.uniq&.compact

        return if urls.blank?

        # Licences coming from the XML seem to have `legalcode` appended to them:
        # I.e. https://creativecommons.org/licenses/by/4.0/legalcode
        # This will not match any of the values in the select menu so this is a fix for now
        urls.map { |url| url.gsub("legalcode", "") }
      end

      # There will be differences in how the url's are structured within the data (10.7925/drs1.duchas_5019334).
      # Because of this they may be missing, so we should fallback to the DOI.
      def write_official_link
        Array(url || "https//doi.org/#{doi}")
      end

      def write_journal_title
        return unless container.present? && container.dig("type") == "Journal"

        [container&.dig("title")].compact
      end

      def write_volume
        container&.dig("volume")
      end

      def write_abstract
        return nil if descriptions.blank?

        Array.wrap(descriptions).pluck("description")&.map { |d| Array(d).join("\n") }
      end

      def write_date_published
        date_published
      end

      def write_funder
        grouped_funders&.map do |funder|
          funder.transform_keys!(&:underscore)

          # TODO: Need to get the award name from the number here
          funder["funder_award"] = Array.wrap(funder.delete("award_number"))

          regex = Bolognese::Writers::HykuAddonsWorkFormFieldsWriter::DOI_REGEX
          if (doi = funder["funder_identifier"]&.match(regex)).present?
            # Ensure we only ever use the doi_id and not the full URL
            funder["funder_doi"] = doi[0]

            data = get_funder_ror(funder["funder_doi"])
            data.dig("external_ids")&.each do |type, values|
              funder["funder_#{type.downcase}"] = values["preferred"] || values["all"].first
            end

            funder["funder_ror"] = data.dig("id")
          end

          funder
        end
      end

      # Book chapters have a distinct Book Title field for their parent books title
      def write_book_title
        [container&.dig("title")].compact
      end

      # The following is required for when first and last pages are entered/missing
      # f: 9
      # l: 27
      # res: 9-27
      # =======
      # f: 9
      # l:
      # res: 9
      # =======
      # f:
      # l: 27
      # res: 27
      def write_pagination
        return if container.blank?

        pagination = [container.dig("firstPage"), "-", container.dig("lastPage")].compact

        if pagination.size == 3
          [pagination.join("")]

        # If we don't have a full array, remove the hyphen and return what we have
        else
          pagination.compact.reject { |a| a == "-" }
        end
      end

      protected

        def write_participants(type)
          key = type.to_s.singularize

          meta.dig(type)&.map do |item|
            # transform but don't change original or each time method is run it prepends the key
            trans = item.transform_keys { |k| "#{key}_#{k.underscore}" }

            # Individual name identifiers will require specific tranformations as required
            trans["#{key}_name_identifiers"]&.each_with_object(trans) do |hash, identifier|
              identifier["#{key}_#{hash['nameIdentifierScheme'].downcase}"] = hash["nameIdentifier"]
            end

            # We need to ensure that the field is named properly if we have an organisation if its not blank
            label = Bolognese::Writers::HykuAddonsWorkFormFieldsWriter::UNAVAILABLE_LABEL
            if trans.dig("#{key}_name_type") == "Organizational" && trans["#{key}_name"] != label
              trans["#{key}_organization_name"] = trans.delete("#{key}_name")

            # Incase edge cases don't provide a full set of name values, but should have: 10.7925/drs1.duchas_5019334
            elsif trans["#{key}_name"]&.match?(/,/) && trans["#{key}_given_name"].blank?
              trans["#{key}_family_name"], trans["#{key}_given_name"] = trans["#{key}_name"].split(", ")
            end

            trans
          end
        end

        # Always returns a hash
        def get_funder_ror(funder_doi)
          # doi should be similar to "10.13039/501100000267" however we only want the second segment
          response = Faraday.get("#{Bolognese::Writers::HykuAddonsWorkFormFieldsWriter::ROR_QUERY_URL}#{funder_doi.split('/').last}")

          return {} unless response.success?

          # `body.items` is an array of hashes - but we only need the first one
          JSON.parse(response.body)&.dig("items")&.first || {}
        end

        # Dip into a data continer and check for a specific key, returning the value is present
        # bucket would normally be `identifiers` or `container`
        def identifier_by_type(bucket, type)
          Array.wrap(send(bucket))&.find { |id| id["identifierType"] == type }&.dig("identifier")
        end

        # Group the funders by their name, as we might not have a unique DOI for them.
        # This is a big of a sledge hammer approach, but I believe it'll work for now.
        def grouped_funders
          return if funding_references.blank?

          funding_references.group_by { |funder| funder["funderName"] }.map do |_name, group|
            funder = group.first
            funder["awardNumber"] = group.pluck("awardNumber").compact

            funder
          end
        end
    end
  end
end
# rubocop:enable Metrics/ModuleLength
