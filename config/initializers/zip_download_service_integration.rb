
Deepblue::ZipDownloadService.setup do |config|

  config.zip_download_service_debug_verbose = false
  config.zip_download_controller_behavior_debug_verbose = false
  config.zip_download_presenter_behavior_debug_verbose = false

  config.zip_download_enabled = true

  config.zip_download_max_total_file_size_to_download = 10.gigabytes
  config.zip_download_min_total_file_size_to_download_warn = 1.gigabyte

  puts "Deepblue::ZipDownloadService.setup finished"

end
