
Deepblue::ZipDownloadService.setup do |config|

  config.zip_download_service_debug_verbose = true

  # ToDo: convert from these to new variables
  # config.max_work_file_size_to_download = 10_000_000_000
  # config.min_work_file_size_to_download_warn = 1_000_000_000

  config.zip_download_max_total_file_size_to_download = 10.gigabytes
  config.zip_download_min_total_file_size_to_download_warn = 1.gigabyte

end
