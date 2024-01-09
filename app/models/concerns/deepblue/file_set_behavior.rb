# frozen_string_literal: true

module Deepblue

  require_relative '../../../services/deepblue/virus_scan_service'

  module FileSetBehavior
    extend ActiveSupport::Concern

    mattr_accessor :file_set_behavior_debug_verbose, default: Rails.configuration.file_set_behavior_debug_verbose

    include ::Deepblue::VirusScanService

    included do

      after_initialize :set_deepblue_file_set_defaults

      def set_deepblue_file_set_defaults
        return unless new_record?
        # self.file_size = 0
        # self.visibility = 'open'
      end

    end

    def checksum_update_from_files
      LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                 ::Deepblue::LoggingHelper.called_from,
                                 "" ] if file_set_behavior_debug_verbose

      algorithm, value = self.files_checksum_algorithm_and_value

      self['checksum_algorithm'] = algorithm
      self['checksum_value'] = value
      save!( validate: false )
    end

    def checksum_update_from_files!
      checksum_update_from_files
      save!( validate: false )
    end

    def files_checksum_algorithm_and_value
      file = ::Deepblue::MetadataHelper.file_from_file_set self
      return '', '' if file.nil?
      value = file.checksum.value
      algorithm = file.checksum.algorithm
      return algorithm, value
    end

    # Cast to a SolrDocument by querying from Solr
    def to_presenter
      ::Deepblue::LoggingHelper.bold_debug [::Deepblue::LoggingHelper.here,
                                            ::Deepblue::LoggingHelper.called_from,
                                            "id=#{id}",
                                            ""] if false
      CatalogController.new.fetch(id).last
    end

    # def to_ds_file_set_presenter( current_ability )
    #   ::Deepblue::LoggingHelper.bold_debug [::Deepblue::LoggingHelper.here,
    #                                         ::Deepblue::LoggingHelper.called_from,
    #                                         "id=#{id}",
    #                                         ""]
    #   rv = DsFileSetPresenter.new( to_solr, current_ability )
    #   ::Deepblue::LoggingHelper.bold_debug [::Deepblue::LoggingHelper.here,
    #                                         ::Deepblue::LoggingHelper.called_from,
    #                                         "id=#{id}",
    #                                         "rv.class.name=#{rv.class.name}",
    #                                         ""]
    #   return rv
    # end

    def parent_published?
      return false unless parent.present?
      parent.published?
    end

    def parent_tombstoned?
      return false unless parent.present?
      parent.tombstone.present?
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
      debug_verbose = ::Deepblue::VirusScanService.virus_scan_service_debug_verbose || file_set_behavior_debug_verbose
      LoggingHelper.bold_debug [ LoggingHelper.here,
                                 LoggingHelper.called_from, "original_file = #{original_file}",
                                 "" ] if debug_verbose
      # check file size here to avoid making a temp copy of the file in VirusCheckerService
      needed = virus_scan_needed?
      if needed && virus_scan_file_too_big?
        virus_scan_status_update( scan_result: VIRUS_SCAN_SKIPPED_TOO_BIG )
        return false
      elsif needed
        # TODO: figure out how to retry the virus scan as this only works for ( original_file && original_file.new_record? )
        # scan_result = Hydra::Works::VirusCheckerService.file_has_virus? original_file
        scan_result = ::Hyrax::VirusCheckerService.file_has_virus? original_file
        virus_scan_status_update( scan_result: scan_result, previous_scan_result: virus_scan_status )
        return scan_result == ::Deepblue::VirusScanService::VIRUS_SCAN_VIRUS
      else
        logger.info "Virus scan not needed." # TODO: improve message
        return false
      end
    end

    def virus_scan_file_too_big?
      fsize = virus_scan_file_size
      return false if fsize.blank?
      rv = fsize.to_i > Rails.configuration.virus_scan_max_file_size
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
      debug_verbose = ::Deepblue::VirusScanService.virus_scan_service_debug_verbose || file_set_behavior_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if debug_verbose
      return false if original_file.nil?
      return true if original_file && original_file.new_record?
      return false if virus_scan_status.present?
      return true
      # if true # set this to false to skip virus scanning if its already been done
      #   # otherwise, really, it's always needed.
      #   return false if VIRUS_SCAN_ERROR == virus_scan_status
      #   return true
      # else
      #   return true if original_file && original_file.new_record?
      #   # return false unless Rails.configuration.virus_scan_retry
      #   scan_status = virus_scan_status
      #   return true if scan_status.blank?
      #   rv =  case scan_status
      #         when VIRUS_SCAN_NOT_VIRUS
      #           false
      #         when VIRUS_SCAN_VIRUS
      #           false
      #         when VIRUS_SCAN_SKIPPED_TOO_BIG
      #           false
      #         when VIRUS_SCAN_SKIPPED_SERVICE_UNAVAILABLE
      #           false && Rails.configuration.virus_scan_retry_on_service_unavailable
      #         when VIRUS_SCAN_ERROR
      #           false && Rails.configuration.virus_scan_retry_on_error
      #         when VIRUS_SCAN_UNKNOWN
      #           false && Rails.configuration.virus_scan_retry_on_unknown
      #         else
      #           true
      #         end
      # end
    end

    def virus_scan_retry?
      return !( original_file && original_file.new_record? )
    end

    def virus_scan_status_reset( current_user: nil, save: true )
      debug_verbose = ::Deepblue::VirusScanService.virus_scan_service_debug_verbose || file_set_behavior_debug_verbose
      LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                 ::Deepblue::LoggingHelper.called_from,
                                  "" ] if debug_verbose
      added_prov_key_values = { 'prior_virus_scan_service' => self['virus_scan_service'],
                                'prior_virus_scan_status' => self['virus_scan_status'],
                                'prior_virus_scan_status_date' => self['virus_scan_status_date'] }
      self['virus_scan_service'] = nil
      self['virus_scan_status'] = nil
      self['virus_scan_status_date'] = nil
      save!( validate: false ) if save # validating will send it back to be virus checked, which leads to a stack overflow
      provenance_virus_scan( current_user: current_user,
                             scan_result: nil,
                             event_note: 'reset',
                             **added_prov_key_values )
    end

    def virus_scan_status_update( scan_result:, previous_scan_result: nil )
      debug_verbose = ::Deepblue::VirusScanService.virus_scan_service_debug_verbose || file_set_behavior_debug_verbose
      LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                 ::Deepblue::LoggingHelper.called_from,
                                 "scan_result=#{scan_result}",
                                 "previous_scan_result=#{previous_scan_result}",
                                 "" ] if debug_verbose
      # Oops. Really don't want to consider previous result as we want the new timestamp
      # return scan_result if previous_scan_result.present? && scan_result == previous_scan_result
      #
      # for some reason, this does not save the attributes
      # virus_scan_service = virus_scan_service_name
      # virus_scan_status = scan_result
      # virus_scan_status_date = virus_scan_timestamp_now
      #
      # but this does save the attributes
      self['virus_scan_service'] = virus_scan_service_name
      self['virus_scan_status'] = scan_result
      self['virus_scan_status_date'] = virus_scan_timestamp_now
      save!( validate: false ) # validating will send it back to be virus checked, which leads to a stack overflow
      provenance_virus_scan( scan_result: scan_result ) # if respond_to? :provenance_virus_scan
      return scan_result
    end

  end

end
