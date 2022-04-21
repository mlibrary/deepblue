# frozen_string_literal: true

module Deepblue

  module VirusScanService

    mattr_accessor :virus_scan_service_debug_verbose, default: false

    VIRUS_SCAN_ERROR = 'scan error'.freeze unless const_defined? :VIRUS_SCAN_ERROR
    VIRUS_SCAN_NOT_VIRUS = 'not virus'.freeze unless const_defined? :VIRUS_SCAN_NOT_VIRUS
    VIRUS_SCAN_SKIPPED = 'scan skipped'.freeze unless const_defined? :VIRUS_SCAN_SKIPPED
    VIRUS_SCAN_SKIPPED_SERVICE_UNAVAILABLE = 'scan skipped service unavailable'.freeze unless const_defined? :VIRUS_SCAN_SKIPPED_SERVICE_UNAVAILABLE
    VIRUS_SCAN_SKIPPED_TOO_BIG = 'scan skipped too big'.freeze unless const_defined? :VIRUS_SCAN_SKIPPED_TOO_BIG
    VIRUS_SCAN_UNKNOWN = 'scan unknown'.freeze unless const_defined? :VIRUS_SCAN_UNKNOWN
    VIRUS_SCAN_VIRUS = 'virus'.freeze unless const_defined? :VIRUS_SCAN_VIRUS

    def virus_scan_detected_virus?( scan_result: )
      VIRUS_SCAN_VIRUS == scan_result
    end

    def virus_scan_service_name
      Hydra::Works.default_system_virus_scanner.name
    end

    def virus_scan_skipped?( scan_result: )
      return false if scan_result.blank?
      scan_result.start_with? 'scan skipped'
    end

    def virus_scan_timestamp_now
      Time.now.to_formatted_s(:db )
    end

  end

end
