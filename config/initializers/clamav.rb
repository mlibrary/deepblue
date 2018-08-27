# frozen_string_literal: true

# ClamAV.instance.loaddb if defined? ClamAV
require "default_virus_scanner"
require "umich_clamav_daemon_scanner"

if defined? ClamAV && ENV['CI'] != 'true'
  require "umich_clamav_daemon_scanner"
  Hydra::Works.default_system_virus_scanner = UMichClamAVDaemonScanner
  Rails.logger.info "Using ClamAV Daemon"
else
  require "default_virus_scanner"
  Hydra::Works.default_system_virus_scanner = DefaultVirusScanner
  Rails.logger.warn "No virus check in use."
end
