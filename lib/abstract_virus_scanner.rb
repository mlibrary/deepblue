# frozen_string_literal: true

class AbstractVirusScanner < Hydra::Works::VirusScanner

  def initialize( file )
    super( file )
  end

  def clam_av_scanner
    scan_result = ClamAV.instance.method(:scanfile).call(file)
    return scan_no_virus if scan_result.zero?
    warning "A virus was found in #{file}: #{scan_result}"
    scan_virus
  end

  # return one of:
  # Hydra::Works::VirusCheck::VIRUS_SCAN_ERROR = 'scan error'
  # Hydra::Works::VirusCheck::VIRUS_SCAN_NOT_VIRUS = 'not virus'
  # Hydra::Works::VirusCheck::VIRUS_SCAN_SKIPPED = 'scan skipped'
  # Hydra::Works::VirusCheck::VIRUS_SCAN_SKIPPED = 'scan skipped'
  # Hydra::Works::VirusCheck::VIRUS_SCAN_SKIPPED_SERVICE_UNAVAILABLE = 'scan skipped service unavailable'
  # Hydra::Works::VirusCheck::VIRUS_SCAN_SKIPPED_TOO_BIG = 'scan skipped too big'
  # Hydra::Works::VirusCheck::VIRUS_SCAN_UNKNOWN = 'scan unknown'
  # Hydra::Works::VirusCheck::VIRUS_SCAN_VIRUS = 'virus'
  #
  def infected?
    rv = super
    return rv
  end

  def null_scanner
    warning "Unable to check #{file} for viruses because no virus scanner is defined"
    scan_skipped
  end

  def scan_error
    Hydra::Works::VirusCheck::VIRUS_SCAN_ERROR
  end

  def scan_no_virus
    Hydra::Works::VirusCheck::VIRUS_SCAN_NO_VIRUS
  end

  def scan_skipped
    Hydra::Works::VirusCheck::VIRUS_SCAN_SKIPPED
  end

  def scan_skipped_service_unavailable
    Hydra::Works::VirusCheck::VIRUS_SCAN_SKIPPED_SERVICE_UNAVAILABLE
  end

  def scan_skipped_too_big
    Hydra::Works::VirusCheck::VIRUS_SCAN_SKIPPED_TOO_BIG
  end

  def scan_unknown
    Hydra::Works::VirusCheck::VIRUS_SCAN_UNKNOWN
  end

  def scan_virus
    Hydra::Works::VirusCheck::VIRUS_SCAN_VIRUS
  end

end
