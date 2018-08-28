# frozen_string_literal: true

module Hydra::Works

  module VirusCheck
    extend ActiveSupport::Concern

    VIRUS_SCAN_ERROR = 'scan error'
    VIRUS_SCAN_NOT_VIRUS = 'not virus'
    VIRUS_SCAN_SKIPPED = 'scan skipped'
    VIRUS_SCAN_SKIPPED_NOT_NEW = 'scan skipped not new'
    VIRUS_SCAN_SKIPPED_SERVICE_UNAVAILABLE = 'scan skipped service unavailable'
    VIRUS_SCAN_SKIPPED_TOO_BIG = 'scan skipped too big'
    VIRUS_SCAN_UNKNOWN = 'scan unknown'
    VIRUS_SCAN_VIRUS = 'virus'

    included do
      validate :must_not_detect_viruses

      def viruses?
        # check file size here to avoid making a temp copy of the file in VirusCheckerService
        scan_result = if !( original_file && original_file.new_record? )
                        VIRUS_SCAN_SKIPPED_NOT_NEW
                      elsif original_file.size > DeepBlueDocs::Application.config.virus_scan_max_file_size
                        VIRUS_SCAN_SKIPPED_TOO_BIG
                      else
                        VirusCheckerService.file_has_virus? original_file
                      end
        return false if VIRUS_SCAN_SKIPPED_NOT_NEW == scan_result
        service = Hydra::Works.default_system_virus_scanner.name
        # of_resolved = resolve_original_file original_file
        provenance_virus_check( virus_check_service: service, scan_result: scan_result ) if respond_to? :provenance_virus_check
        return VIRUS_SCAN_VIRUS == scan_result
      end

      def resolve_original_file( original_file )
        return original_file if original_file.is_a? String
        return original_file.original_name if original_file.respond_to? :original_name
        return label
      end

      def must_not_detect_viruses
        return true unless viruses?
        errors.add( :base, "Failed to verify uploaded file is not a virus" )
        false
      end

    end

  end

end
