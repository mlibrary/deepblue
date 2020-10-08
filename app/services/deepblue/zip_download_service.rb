# frozen_string_literal: true

module Deepblue

  class ZipDownloadService

    @@zip_download_service_debug_verbose = false
    @@zip_download_controller_behavior_debug_verbose = false
    @@zip_download_presenter_behavior_debug_verbose = false

    @@zip_download_enabled = true
    @@zip_download_max_total_file_size_to_download = 10.gigabytes
    @@zip_download_min_total_file_size_to_download_warn = 1.gigabyte

    mattr_accessor :zip_download_service_debug_verbose,
                   :zip_download_controller_behavior_debug_verbose,
                   :zip_download_presenter_behavior_debug_verbose,
                   :zip_download_enabled,
                   :zip_download_max_total_file_size_to_download,
                   :zip_download_min_total_file_size_to_download_warn

    @@_setup_ran = false

    def self.setup
      yield self if @@_setup_ran == false
      @@_setup_ran = true
    end

  end

end
