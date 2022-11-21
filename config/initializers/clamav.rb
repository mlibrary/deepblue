# frozen_string_literal: true

# ClamAV.instance.loaddb if defined? ClamAV

if defined? ClamAV && ENV['CI'] != 'true'
  require "umich_clamav_daemon_scanner"
  Hydra::Works.default_system_virus_scanner = UMichClamAVDaemonScanner
  Hyrax::VirusCheckerService.default_system_virus_scanner = UMichClamAVDaemonScanner
  Rails.logger.info "Using ClamAV Daemon virus checker."
else
  require "null_virus_scanner"
  Hydra::Works.default_system_virus_scanner = NullVirusScanner
  Hyrax::VirusCheckerService.default_system_virus_scanner = NullVirusScanner
  Rails.logger.warn "No virus checker in use."
end
puts "Hyrax::VirusCheckerService.default_system_virus_scanner=#{Hyrax::VirusCheckerService.default_system_virus_scanner}"
