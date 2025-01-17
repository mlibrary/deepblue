# frozen_string_literal: true
require 'bolognese' if Rails.configuration.use_bolognese

module Bolognese
  module Readers
    # Use this with Bolognese like the following:
    # m = Bolognese::Metadata.new(input: work.attributes.merge(has_model: work.has_model.first).to_json, from: 'hyrax_work')
    # Then crosswalk it with:
    # m.datacite
    # Or:
    # m.ris
    module HyraxWorkReader

      mattr_accessor :bolognese_hyrax_work_readers_debug_verbose,
                     default: ::Deepblue::DoiMintingService.bolognese_hyrax_work_readers_debug_verbose

      # Not usable right now given how Metadata#initialize works
      # def get_hyrax_work(id: nil, **options)
      #   work = PersistHelper.find(id)
      #   { "string" => work.attributes.merge(has_model: work.has_model).to_json }
      # end

      def read_hyrax_work(string: nil, **options)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "" ] if bolognese_hyrax_work_readers_debug_verbose
        read_options = ActiveSupport::HashWithIndifferentAccess.new(options.except(:doi, :id, :url, :sandbox, :validate, :ra))

        meta = string.present? ? Maremma.from_json(string) : {}

        {
          # "id" => meta.fetch('id', nil),
          "identifiers" => read_hyrax_work_identifiers(meta),
          "types" => read_hyrax_work_types(meta),
          "doi" => normalize_doi(meta.fetch('doi', nil)&.first),
          # "url" => normalize_id(meta.fetch("URL", nil)),
          "titles" => read_hyrax_work_titles(meta),
          "creators" => read_hyrax_work_creators(meta),
          "contributors" => read_hyrax_work_contributors(meta),
          # "container" => container,
          "publisher" => read_hyrax_work_publisher(meta),
          # "related_identifiers" => related_identifiers,
          # "dates" => dates,
          "publication_year" => read_hyrax_work_publication_year(meta),
          "descriptions" => read_hyrax_work_descriptions(meta),
          # "rights_list" => rights_list,
          # "version_info" => meta.fetch("version", nil),
          "subjects" => read_hyrax_work_subjects(meta)
          # "state" => state
        }.merge(read_options)
      end

      private

      def read_hyrax_work_types(meta)
        # TODO: Map work.resource_type or work.
        resource_type_general = "Other"
        hyrax_resource_type = meta.fetch('has_model', nil) || "Work"
        hyrax_resource_type = hyrax_resource_type[0] if hyrax_resource_type.is_a? Array
        resource_type = meta.fetch('resource_type', nil).presence || hyrax_resource_type
        resource_type = resource_type[0] if resource_type.is_a? Array
        {
          "resourceTypeGeneral" => resource_type_general,
          "resourceType" => resource_type,
          "hyrax" => hyrax_resource_type
        }.compact
      end

      def read_hyrax_work_creators(meta)
        get_authors(Array.wrap(meta.fetch("creator", nil))) if meta.fetch("creator", nil).present?
      end

      def read_hyrax_work_contributors(meta)
        get_authors(Array.wrap(meta.fetch("contributor", nil))) if meta.fetch("contributor", nil).present?
      end

      def read_hyrax_work_titles(meta)
        Array.wrap(meta.fetch("title", nil)).select(&:present?).collect { |r| { "title" => sanitize(r) } }
      end

      def read_hyrax_work_descriptions(meta)
        Array.wrap(meta.fetch("description", nil)).select(&:present?).collect { |r| { "description" => sanitize(r) } }
      end

      def read_hyrax_work_publication_year(meta)
        date = meta.fetch("date_created", nil)&.first
        date ||= meta.fetch("date_uploaded", nil)
        Date.edtf(date.to_s).year
      rescue StandardError
        Time.zone.today.year
      end

      def read_hyrax_work_subjects(meta)
        Array.wrap(meta.fetch("keyword", nil)).select(&:present?).collect { |r| { "subject" => sanitize(r) } }
      end

      def read_hyrax_work_identifiers(meta)
        Array.wrap(meta.fetch("identifier", nil)).select(&:present?).collect { |r| { "identifier" => sanitize(r) } }
      end

      def read_hyrax_work_publisher(meta)
        # Fallback to ':unav' since this is a required field for datacite
        # TODO: Should this default to application_name?
        parse_attributes(meta.fetch("publisher")).to_s.strip.presence || ":unav"
      end
    end
  end
end
