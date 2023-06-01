# frozen_string_literal: true
# hyrax-orcid

# rubocop:disable Metrics/ClassLength
module Bolognese
  module Writers
    module Orcid
      class HyraxXmlBuilder
        PERMITTED_EXTERNAL_IDENTIFIERS = %w[issn isbn].freeze
        CONTRIBUTOR_MAP = {
          "author" => ["Author"],
          "assignee" => [],
          "editor" => ["Editor"],
          "chair-or-translator" => ["Translator"],
          "co-investigator" => [],
          "co-inventor" => [],
          "graduate-student" => [],
          "other-inventor" => [],
          "principal-investigator" => [],
          "postdoctoral-researcher" => [],
          "support-staff" => ["Other"]
        }.freeze
        DEFAULT_CONTRIBUTOR_ROLE = "support-staff"

        @debug_verbose = false

        def initialize(xml:, metadata:, type:)
          ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "xml=#{xml.pretty_inspect}",
                                                 "metadata=#{metadata.pretty_inspect}",
                                                 "type=#{type.pretty_inspect}",
                                                 "" ] if @debug_verbose
          @xml = xml
          @metadata = metadata
          @type = type
        end

        # Fields guide:
        # https://github.com/ORCID/ORCID-Source/blob/master/orcid-api-web/tutorial/works.md#work-fields
        def build
          ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "@xml=#{@xml.pretty_inspect}",
                                                "@metadata=#{@metadata.pretty_inspect}",
                                                "@metadata.class.name=#{@metadata.class.name}",
                                                 "@type=#{@type.pretty_inspect}",
                                                 "" ] if @debug_verbose

          # ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here,
          #                                        ::Deepblue::LoggingHelper.called_from,
          #                                        "@xml[:work]=#{@xml[:work].pretty_inspect}",
          #                                        "" ] if @debug_verbose
          @xml[:work].title do
            @xml[:common].title @metadata.titles.first.dig("title")
          end

          xml_short_description
          ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "@xml[:work]=#{@xml[:work].pretty_inspect}",
                                                 "" ] if @debug_verbose
          xml_work_type

          # NOTE: A full list of external-id-type: https://pub.orcid.org/v2.1/identifiers
          @xml[:common].send("external-ids") do
            xml_internal_identifier
            xml_external_doi
            xml_external_identifiers
          end

          @xml[:work].contributors do
            xml_creators
            xml_contributors
          end
        end
        # rubocop:enable Metrics/MethodLength

        protected

          # NOTE: Allowed work types - this are found in the work-2.1.xsd
          # artistic-performance, book-chapter, book-review, book, conference-abstract, conference-paper, conference-poster, data-set, dictionary-entry, disclosure, dissertation, edited-book, encyclopedia-entry, invention, journal-article, journal-issue, lecture-speech, license, magazine-article, manual, newsletter-article, newspaper-article, online-resource, other, patent, registered-copyright, report, research-technique, research-tool, spin-off-company, standards-and-policy, supervised-student-publication, technical-standard, test, translation, trademark, website, working-paper
          def xml_work_type
            @xml[:work].type @type
          end

          def xml_short_description
            description = @metadata.descriptions.first&.dig("description") || ""
            ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here,
                                                   ::Deepblue::LoggingHelper.called_from,
                                                   "description=#{description}",
                                                   "" ] if @debug_verbose

            # The maximum length of this field is 5000 and truncate appends an ellipsis
            rv = @xml[:work].send("short-description", description.truncate(4997))
            ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here,
                                                   ::Deepblue::LoggingHelper.called_from,
                                                   "rv=#{rv.pretty_inspect}",
                                                   "" ] if @debug_verbose

            return rv
          end

          def xml_internal_identifier
            # We should always have a UUID, but specs might not be saving works and will fail otherwise
            return if @metadata.id.blank?

            @xml[:common].send("external-id") do
              @xml[:common].send("external-id-type", "other-id")
              @xml[:common].send("external-id-value", @metadata.id)
              @xml[:common].send("external-id-relationship", "self")
            end
          end

          def xml_external_doi
            return if @metadata.doi.blank?

            @xml[:common].send("external-id") do
              @xml[:common].send("external-id-type", "doi")
              @xml[:common].send("external-id-value", @metadata.doi&.gsub("https://doi.org/", ""))
              @xml[:common].send("external-id-url", @metadata.doi)
              @xml[:common].send("external-id-relationship", "self")
            end
          end

          def xml_external_identifiers
            PERMITTED_EXTERNAL_IDENTIFIERS.each do |item|
              next if (value = @metadata.meta.dig(item)).blank?

              @xml[:common].send("external-id") do
                @xml[:common].send("external-id-type", item)
                @xml[:common].send("external-id-value", value)
                @xml[:common].send("external-id-relationship", "self")
              end
            end
          end

          def xml_creators_orig
            return if @metadata.creators.blank?

            @metadata.creators.each_with_index do |creator, i|
              @xml[:work].contributor do
                xml_contributor_orcid(find_valid_orcid(creator))
                xml_contributor_name(creator.dig("name"))
                xml_contributor_role(i.zero?, "Author")
              end
            end
          end

          def xml_creators
            ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here,
                                                  ::Deepblue::LoggingHelper.called_from,
                                                  "@metadata.creators=#{@metadata.creators.pretty_inspect}",
                                                  "" ] if @debug_verbose
            return if @metadata.creators.blank?

            @metadata.creators.each_with_index do |creator, i|
              ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here,
                                                    ::Deepblue::LoggingHelper.called_from,
                                                    "creator=#{creator.pretty_inspect}",
                                                    "" ] if @debug_verbose
              @xml[:work].contributor do
                orcid = find_valid_orcid(creator)
                xml_contributor_orcid(orcid)
                xml_contributor_name(creator.dig("name"))
                #xml_contributor_name("creator name")
                xml_contributor_role(i.zero?, "Author")
              end
            end
          end

          def xml_contributors
            ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here,
                                                  ::Deepblue::LoggingHelper.called_from,
                                                  "@metadata.contributors=#{@metadata.contributors.pretty_inspect}",
                                                  "" ] if @debug_verbose
            return if @metadata.contributors.blank?

            @metadata.contributors.each do |contributor|
              @xml[:work].contributor do
                xml_contributor_orcid(find_valid_orcid(contributor))
                xml_contributor_name(contributor.dig("name"))
                xml_contributor_role(false, contributor["contributorType"])
              end
            end
          end

          def xml_contributor_name(name)
            ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here,
                                                  ::Deepblue::LoggingHelper.called_from,
                                                  "name=#{name}",
                                                  "" ] if @debug_verbose
            @xml[:work].send("credit-name", name)
          end

          def xml_contributor_role(primary = true, role = "Author")
            @xml[:work].send("contributor-attributes") do
              @xml[:work].send("contributor-sequence", primary ? "first" : "additional")

              @xml[:work].send("contributor-role", orcid_role(role))
            end
          end

          def xml_contributor_orcid(orcid)
            ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here,
                                                  ::Deepblue::LoggingHelper.called_from,
                                                  "orcid=#{orcid}",
                                                  "" ] if @debug_verbose
            return if orcid.blank?

            @xml[:common].send("contributor-orcid") do
              @xml[:common].uri "https://orcid.org/#{orcid}"
              @xml[:common].path orcid
              @xml[:common].host "orcid.org"
            end
          end

          def find_valid_orcid(hsh)
            ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here,
                                                   ::Deepblue::LoggingHelper.called_from,
                                                   "hsh=#{hsh.pretty_inspect}",
                                                   "" ] if @debug_verbose
            identifier = hsh["nameIdentifiers"]&.find { |id| id["nameIdentifierScheme"] == "orcid" }
            ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here,
                                                  ::Deepblue::LoggingHelper.called_from,
                                                  "identifier=#{identifier}",
                                                  "" ] if @debug_verbose

            @metadata.validate_orcid(identifier&.dig("nameIdentifier"))
          end

          def orcid_role(role)
            CONTRIBUTOR_MAP.find { |_k, v| v.include?(role) }&.first || DEFAULT_CONTRIBUTOR_ROLE
          end
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
