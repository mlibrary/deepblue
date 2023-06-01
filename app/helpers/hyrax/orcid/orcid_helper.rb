# frozen_string_literal: true
# hyrax-orcid

module Hyrax
  module Orcid
    module OrcidHelper

      # mattr_accessor :orcid_json_fields, default: %i[creator contributor]

      # Originally taken from Bolognese, however theirs doesn't account for no space/- delimiter.
      #
      # The Orcid reference is incomplete and can have variations on the structure set out here:
      # https://support.orcid.org/hc/en-us/articles/360006897674-Structure-of-the-ORCID-Identifier
      #
      # The following could also be given:
      # 000000029079593X
      # 0000 0002 9079 593X
      # 0000-0002-9079-593X - note the X here
      # 0000-1234-1234-1234
      ORCID_REGEX = %r{
        (?:(?:http|https):\/\/
        (?:www\.(?:sandbox\.)?)?orcid\.org\/)?
        (\d{4}[[:space:]-]?\d{4}[[:space:]-]?\d{4}[[:space:]-]?(\d{3}X|\d{4}))
      }x

      # FIXME: OrcidHelper.json_fields should be a configuration option
      def self.json_fields
        # %i[creator contributor]
        %i[creator]
      end

      def self.validate_orcid(orcid)
        debug_verbose = ::Hyrax::OrcidIntegrationService.hyrax_orcid_helper_debug_verbose
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "orcid=#{orcid}",
                                               "" ] if debug_verbose
        return if orcid.blank?

        # [0] full match
        # [1] only the orcid ID - the one we want
        # [2] last 4 digits
        orcid = Array.wrap(orcid.match(ORCID_REGEX).to_a).second
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "orcid=#{orcid}",
                                               "" ] if debug_verbose

        return if orcid.blank?

        # If we have a valid Orcid ID, remove anything that isn't a number or an X, group into 4's and hyphen delimit
        rv = orcid.gsub(/[^\dX]/, "").scan(/.{1,4}/).join("-")
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "rv=#{rv}",
                                               "" ] if debug_verbose

        return rv
      end

      def validate_orcid( orcid )
        OrcidHelper::validate_orcid( orcid )
      end

    end
  end
end
