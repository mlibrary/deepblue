# frozen_string_literal: true

module Deepblue

  class ZipDownloadService

    @@_setup_ran = false
    @@_setup_failed = false

    def self.setup
      yield self unless @@_setup_ran
      @@_setup_ran = true
    rescue Exception => e # rubocop:disable Lint/RescueException
      @@_setup_failed = true
      msg = "#{e.class}: #{e.message} at #{e.backtrace.join("\n")}"
      # rubocop:disable Rails/Output
      puts msg
      # rubocop:enable Rails/Output
      Rails.logger.error msg
      raise e
    end

    mattr_accessor :zip_download_service_debug_verbose, default: false
    mattr_accessor :zip_download_controller_behavior_debug_verbose, default: false
    mattr_accessor :zip_download_presenter_behavior_debug_verbose, default: false

    mattr_accessor :zip_download_enabled, default: true
    mattr_accessor :zip_download_max_total_file_size_to_download, default: 10.gigabytes
    mattr_accessor :zip_download_min_total_file_size_to_download_warn, default: 1.gigabyte

  end

end
