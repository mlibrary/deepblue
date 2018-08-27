# frozen_string_literal: true

# ClamAV.instance.loaddb if defined? ClamAV
require "umich_clamav_daemon_scanner"

if defined? ClamAV && ENV['CI'] != 'true'
  require "umich_clamav_daemon_scanner"
  Hydra::Works.default_system_virus_scanner = UMichClamAVDaemonScanner
  Rails.logger.info "Using ClamAV Daemon"
else
  Rails.logger.warn "No virus check in use."
end
