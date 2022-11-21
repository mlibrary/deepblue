# frozen_string_literal: true

class AbstractVirusScanner < Hydra::Works::VirusScanner

  mattr_accessor :abstract_virus_scanner_debug_verbose,
                 default: ::Deepblue::VirusScanService.abstract_virus_scanner_debug_verbose

  def initialize( filename )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "filename=#{filename}",
                                           "" ] if abstract_virus_scanner_debug_verbose
    super( filename )
  end

  def clam_av_scanner
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if abstract_virus_scanner_debug_verbose
    scan_result = ClamAV.instance.method(:scanfile).call(file)
    return ::Deepblue::VirusScanService::VIRUS_SCAN_NOT_VIRUS if scan_result.zero?
    warning "A virus was found in #{file}: #{scan_result}"
    ::Deepblue::VirusScanService::VIRUS_SCAN_VIRUS
  end

  def infected?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if abstract_virus_scanner_debug_verbose
    ::Deepblue::VirusScanService::VIRUS_SCAN_SKIPPED
  end

  def null_scanner
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if abstract_virus_scanner_debug_verbose
    warning "Unable to check #{file} for viruses because no virus scanner is defined"
    ::Deepblue::VirusScanService::VIRUS_SCAN_SKIPPED_SERVICE_UNAVAILABLE
  end

end
