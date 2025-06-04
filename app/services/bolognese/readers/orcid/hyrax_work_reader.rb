# frozen_string_literal: true
# hyrax-orcid

require 'bolognese' if Rails.configuration.use_bolognese

# Inpired by the Hyrax-DOI writer
# @credit Chris Colvard <chris.colvard@gmail.com>
module Bolognese
  module Readers
    module Orcid
      module HyraxWorkReader
        OPTION_EXCLUDES = %i[doi id url sandbox validate ra].freeze

        @debug_verbose = false

        # see: https://github.com/ORCID/orcid-model/blob/master/src/main/resources/record_2.1/samples/write_sample/work-full-2.1.xml
        #

        def read_hyrax_json_work(string: nil, **options)
          read_options = ActiveSupport::HashWithIndifferentAccess.new(options.except(*OPTION_EXCLUDES))

          meta = string.present? ? Maremma.from_json(string) : {}

          {
            "id" => meta.fetch('id', nil),
            "identifiers" => read_hyrax_json_work_identifiers(meta),
            "types" => read_hyrax_json_work_types(meta),
            "doi" => normalize_doi(meta.fetch('doi', nil)&.first),
            "titles" => read_hyrax_json_work_titles(meta),
            "creators" => read_hyrax_json_work_creators(meta),
            "contributors" => read_hyrax_json_work_contributors(meta),
            "publication_year" => read_hyrax_json_work_publication_year(meta),
            "descriptions" => read_hyrax_json_work_descriptions(meta),
            "subjects" => read_hyrax_json_work_subjects(meta)
          }.merge(read_options)
        end

        private

          def read_hyrax_json_work_types(meta)
            # TODO: Map work.resource_type or work.
            resource_type_general = "Other"
            hyrax_resource_type = meta.fetch('has_model', nil) || "Work"
            resource_type = meta.fetch('resource_type', nil).presence || hyrax_resource_type
            {
              "resourceTypeGeneral" => resource_type_general,
              "resourceType" => resource_type,
              "hyrax" => hyrax_resource_type
            }.compact
          end

          def read_hyrax_json_work_creators(meta)
            orcid_json_authors(meta, :creator)
          end

          def read_hyrax_json_work_contributors(meta)
            orcid_json_authors(meta, :contributor)
          end

          def read_hyrax_json_work_titles(meta)
            Array.wrap(meta.fetch("title", nil)).select(&:present?).collect { |r| { "title" => sanitize(r) } }
          end

          def read_hyrax_json_work_descriptions(meta)
            Array.wrap(meta.fetch("description", nil)).select(&:present?).collect { |r| { "description" => sanitize(r) } }
          end

          def read_hyrax_json_work_publication_year(meta)
            date = meta.fetch("date_created", nil)&.first
            date ||= meta.fetch("date_uploaded", nil)
            Date.edtf(date.to_s).year
          rescue StandardError
            Time.zone.today.year
          end

          def read_hyrax_json_work_subjects(meta)
            Array.wrap(meta.fetch("keyword", nil)).select(&:present?).collect { |r| { "subject" => sanitize(r) } }
          end

          def read_hyrax_json_work_identifiers(meta)
            Array.wrap(meta.fetch("identifier", nil)).select(&:present?).collect { |r| { "identifier" => sanitize(r) } }
          end

          def read_hyrax_json_work_publisher(meta)
            # Fallback to ':unav' since this is a required field for datacite
            # TODO: Should this default to application_name?
            parse_attributes(meta.fetch("publisher")).to_s.strip.presence || ":unav"
          end

          # Prepare the json to be parsed through Bolognese get_authors method
          #
          # NOTE: The downcase is to counteract Bolognese potentially titleizing the values
          def prepare_author_json_fields_orig(type, json)
            obj = JSON.parse(json)
            transformed = Array.wrap(obj).map { |c| c.transform_keys { |k| k.camelize(:lower) } }

            transformed.each do |t|
              # check for `creatorOrcid` or `contributorOrcid
              next if t["#{type}Orcid"].blank?

              t["nameIdentifier"] = { "nameIdentifierScheme" => "orcid", "__content__" => t["#{type}Orcid"].downcase }
            end

            transformed.compact

          rescue JSON::ParserError
            json
          end

          def prepare_author_fields(type, values, value_orcid)
            ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here,
                                                  ::Deepblue::LoggingHelper.called_from,
                                                  "type=#{type}",
                                                  "values=#{values}",
                                                  "value_orcid=#{value_orcid}",
                                                  "" ] if @debug_verbose
            t = []
            # TODO: loop with indexes
            values.each_with_index do |value,index|
              ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here,
                                                    ::Deepblue::LoggingHelper.called_from,
                                                    "value=#{value}",
                                                    "index=#{index}",
                                                    "value_orcid[index]=#{value_orcid[index]}",
                                                    "" ] if @debug_verbose

              orcid = ::Hyrax::Orcid::OrcidHelper.validate_orcid( value_orcid[index] )

              # TODO: need to look for "creator_orcid"
              # check for `creatorOrcid` or `contributorOrcid
              # next if t["#{type}Orcid"].blank?

              # TODO: this needs to come from "creator_orcid"
              # TODO: orcid can be nil
              orcid.downcase! if orcid.present?
              t << { "nameIdentifier" => { "nameIdentifierScheme" => "orcid",
                                           "__content__" => orcid },
                     "#{type}Name" => value }

            end

            t.compact
          rescue JSON::ParserError => e
            ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here,
                                                  ::Deepblue::LoggingHelper.called_from,
                                                  "error e=#{e}",
                                                  "" ] if @debug_verbose
            values
          end

          def orcid_json_authors_orig(meta, type)
            return if (value = meta.dig(type.to_s)).blank?

            author = if meta.dig("has_model").constantize.json_fields.include?(type.to_sym)
                       prepare_author_json_fields(type.to_sym, value.first)
                     else
                       Array.wrap(value)
                     end

            get_authors(author)
          end

          def orcid_json_authors(metadata, type)
            ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here,
                                                  ::Deepblue::LoggingHelper.called_from,
                                                  "type=#{type}",
                                                  "" ] if @debug_verbose
            ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here,
                                                  ::Deepblue::LoggingHelper.called_from,
                                                  "metadata=#{metadata.pretty_inspect}",
                                                  "" ] if @debug_verbose
            values = metadata.dig(type.to_s)
            ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here,
                                                  ::Deepblue::LoggingHelper.called_from,
                                                  "values=#{values}",
                                                  "" ] if @debug_verbose
            return if values.blank?
            value_orcid = metadata.dig("#{type.to_s}_orcid")
            ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here,
                                                  ::Deepblue::LoggingHelper.called_from,
                                                  "value_orcid=#{value_orcid}",
                                                  "" ] if @debug_verbose
            return if value_orcid.blank?

            author = if metadata.dig("has_model").constantize.json_fields.include?(type.to_sym)
                       prepare_author_fields(type.to_sym, values, value_orcid)
                     else
                       Array.wrap(values)
                     end
            ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here,
                                                  ::Deepblue::LoggingHelper.called_from,
                                                  "author=#{author}",
                                                  "" ] if @debug_verbose

            get_authors(author)
          end
      end
    end
  end
end
