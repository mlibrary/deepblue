# frozen_string_literal: true

module Deepblue

  class ZipDownloadService

    mattr_accessor :zip_download_service_debug_verbose, default: false
    mattr_accessor :zip_download_controller_behavior_debug_verbose, default: false
    mattr_accessor :zip_download_presenter_behavior_debug_verbose, default: false

    mattr_accessor :zip_download_enabled, default: true
    mattr_accessor :zip_download_max_total_file_size_to_download, default: 10.gigabytes
    mattr_accessor :zip_download_min_total_file_size_to_download_warn, default: 1.gigabyte

    @@_setup_ran = false

    def self.setup
      yield self if @@_setup_ran == false
      @@_setup_ran = true
    end

  end

end
