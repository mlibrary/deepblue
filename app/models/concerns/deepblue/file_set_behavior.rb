# frozen_string_literal: true

module Deepblue

  require_relative '../../../services/deepblue/virus_scan_service'

  module FileSetBehavior
    extend ActiveSupport::Concern

    include ::Deepblue::VirusScanService

    included do

      after_initialize :set_deepblue_file_set_defaults

      def set_deepblue_file_set_defaults
        return unless new_record?
        # self.file_size = 0
        # self.visibility = 'open'
      end

    end

    # versioning

    def versions
      ofile = original_file
      return [] if ofile.nil?
      rv = ofile.versions
      return [] if rv.nil?
      rv = rv.all
    end

    def latest_version
      versions.last
    end

    def latest_version_create_datetime
      version_datetime latest_version
    end

    def version_count
      vers = versions
      return 0 if vers.nil?
      vers.count
    end

    def version_datetime( version )
      return nil if version.nil?
      return '' if version.created.blank?
      DateTime.parse version.created
    end

    def version_datetime_display( version )
      timestamp = version_datetime( version )
      DeepblueHelper.display_timestamp timestamp
    end

    def update_parent
      return if parent.nil?
      parent.total_file_size_add_file_set!( self )
    end

    # virus scanning

    def virus_scan
      LoggingHelper.bold_debug [ LoggingHelper.here, LoggingHelper.called_from, "original_file = #{original_file}" ]
      # check file size here to avoid making a temp copy of the file in VirusCheckerService
      needed = virus_scan_needed?
      if needed && virus_scan_file_too_big?
        virus_scan_status_update( scan_result: VIRUS_SCAN_SKIPPED_TOO_BIG )
      elsif needed
        # TODO: figure out how to retry the virus scan as this only works for ( original_file && original_file.new_record? )
        scan_result = Hydra::Works::VirusCheckerService.file_has_virus? original_file
        virus_scan_status_update( scan_result: scan_result, previous_scan_result: virus_scan_status )
      else
        logger.info "Virus scan not needed." # TODO: improve message
      end
    end

    def virus_scan_file_too_big?
      fsize = virus_scan_file_size
      return false if fsize.blank?
      rv = fsize.to_i > DeepBlueDocs::Application.config.virus_scan_max_file_size
      return rv
    end

    def virus_scan_file_size
      if file_size.blank?
        if original_file.nil?
          0
        elsif original_file.respond_to? :size
          original_file.size
        else
          0
        end
      else
        # file_size[0]
        file_size_value
      end
    end

    def virus_scan_needed?
      # really, it's always needed.
      true
      # LoggingHelper.bold_debug [ LoggingHelper.here, LoggingHelper.called_from ]
      # return true if original_file && original_file.new_record?
      # return false unless DeepBlueDocs::Application.config.virus_scan_retry
      # scan_status = virus_scan_status
      # return true if scan_status.blank?
      # case scan_status
      # when VIRUS_SCAN_NOT_VIRUS
      #   false
      # when VIRUS_SCAN_VIRUS
      #   false
      # when VIRUS_SCAN_SKIPPED_TOO_BIG
      #   false
      # when VIRUS_SCAN_SKIPPED_SERVICE_UNAVAILABLE
      #   DeepBlueDocs::Application.config.virus_scan_retry_on_service_unavailable
      # when VIRUS_SCAN_ERROR
      #   DeepBlueDocs::Application.config.virus_scan_retry_on_error
      # when VIRUS_SCAN_UNKNOWN
      #   DeepBlueDocs::Application.config.virus_scan_retry_on_unknown
      # else
      #   true
      # end
    end

    def virus_scan_retry?
      return !( original_file && original_file.new_record? )
    end

    def virus_scan_status_update( scan_result:, previous_scan_result: nil )
      LoggingHelper.bold_debug [ LoggingHelper.here,
                                 LoggingHelper.called_from,
                               "scan_result=#{scan_result}",
                               "previous_scan_result=#{previous_scan_result}" ]
      # Oops. Really don't want to consider previous result as we want the new timestamp
      # return scan_result if previous_scan_result.present? && scan_result == previous_scan_result
      # for some reason, this does not save the attributes
      # virus_scan_service = virus_scan_service_name
      # virus_scan_status = scan_result
      # virus_scan_status_date = virus_scan_timestamp_now
      # but this does save the attributes
      self['virus_scan_service'] = virus_scan_service_name
      self['virus_scan_status'] = scan_result
      self['virus_scan_status_date'] = virus_scan_timestamp_now
      save! # ( validate: false )
      provenance_virus_scan( scan_result: scan_result ) # if respond_to? :provenance_virus_scan
      return scan_result
    end

  end

end
