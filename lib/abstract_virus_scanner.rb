# frozen_string_literal: true

class AbstractVirusScanner < Hydra::Works::VirusScanner

  def initialize( file )
    super( file )
  end

  def clam_av_scanner
    scan_result = ClamAV.instance.method(:scanfile).call(file)
    return ::Deepblue::VirusScanService::VIRUS_SCAN_NOT_VIRUS if scan_result.zero?
    warning "A virus was found in #{file}: #{scan_result}"
    ::Deepblue::VirusScanService::VIRUS_SCAN_VIRUS
  end

  def infected?
    ::Deepblue::VirusScanService::VIRUS_SCAN_SKIPPED
  end

  def null_scanner
    warning "Unable to check #{file} for viruses because no virus scanner is defined"
    ::Deepblue::VirusScanService::VIRUS_SCAN_SKIPPED_SERVICE_UNAVAILABLE
  end

end
