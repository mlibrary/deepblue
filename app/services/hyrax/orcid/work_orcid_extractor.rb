# frozen_string_literal: true
# hyrax-orcid

module Hyrax
  module Orcid
    class WorkOrcidExtractor
      include Hyrax::Orcid::WorkFormNameHelper
      include Hyrax::Orcid::OrcidHelper

      def initialize(work)
        @work = work
        @orcids = []
      end

      def extract
        debug_verbose = ::Hyrax::OrcidIntegrationService.hyrax_orcid_extractor_debug_verbose
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "@work.class.name=#{@work.class.name}",
                                               "target_terms=#{target_terms}",
                                               "" ] if debug_verbose
        target_terms.each do |term|
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "term=#{term}",
                                                 "" ] if debug_verbose
          target = "#{term}_orcid"
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "target=#{target}",
                                                 "" ] if debug_verbose
          values = value_for_term(target)
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "values=#{values}",
                                                 "" ] if debug_verbose
          next if values.blank?

          # puts "values=#{values}"

          values.each { |orcid| @orcids << validate_orcid( orcid ) }
          #@orcids << validate_orcid( values )

          # rv = json.then { |j| JSON.parse(j) }
          #     .select { |person| person.dig(target).present? }
          #     .each { |person| @orcids << validate_orcid(person.dig(target)) }
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "@orcids=#{@orcids}",
                                                 "" ] if debug_verbose
          return @orcids
        end

        @orcids.compact.uniq

      # If we have no JSON fields, like in default Hyrax, then we should not crash
      rescue JSON::ParserError
        []
      end

      def target_terms
        # FIXME: OrcidHelper.json_fields should be a configuration option
        (OrcidHelper.json_fields & work_type_terms)
      end

      protected

        def json_for_term(term)
          @work.send(term).first
        end

        # Required for WorkFormNameable to function correctly
        def meta_model
          @work.class.name
        end

      def value_for_term(term)
        Array( @work.send(term) )
      end

    end
  end
end
