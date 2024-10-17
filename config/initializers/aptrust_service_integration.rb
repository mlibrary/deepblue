
Aptrust::AptrustIntegrationService.setup do |config|

  puts "Starting Aptrust::AptrustIntegrationService"
  begin

  config.aptrust_integration_debug_verbose = false

  config.allow_deposit            = true
  config.repository               = 'umich.edu'
  config.local_repository         = 'deepbluedata'
  config.storage_option           = 'Glacier-Deep-OR'

  config.bag_checksum_algorithm   = 'md5' # md5, sha1, sha256
  config.bag_delete_manifest_sha1 = true
  # config.bag_checksum_algorithm   = 'sha1' # md5, sha1, sha256
  # config.bag_delete_manifest_sha1 = false
  config.bag_max_file_size        = 1.terabytes - 200.megabytes # max less a bit of buffer
  config.bag_max_total_file_size  = 1.terabytes - 100.megabytes # max less a bit of buffer

  config.cleanup_after_deposit    = true
  config.cleanup_bag              = false
  config.cleanup_bag_data         = true

  config.default_access           = 'Institution'
  config.default_creator          = ''
  config.default_description      = 'No description.'
  config.default_item_description = 'No item description.'
  config.default_storage_option   = 'Glacier-Deep-OR'
  config.default_title            = 'No Title'

  # use these values from the DataSetContoller when launching an AptrustUploadWorkJob
  config.from_controller_cleanup_after_deposit        = true
  config.from_controller_cleanup_before_deposit       = true
  config.from_controller_cleanup_bag                  = false
  config.from_controller_cleanup_bag_data             = true
  config.from_controller_clear_status                 = true
  config.from_controller_debug_assume_upload_succeeds = true
  config.from_controller_debug_verbose                = true

  case Rails.configuration.hostname
  when ::Deepblue::InitializationConstants::HOSTNAME_PROD
    config.deposit_context = ''
    config.download_dir = '/deepbluedata-prep/aptrust_download/'
    config.export_dir = '/deepbluedata-prep-new/aptrust/'
    config.working_dir = '/deepbluedata-prep-new/aptrust/'
    config.from_controller_debug_assume_upload_succeeds = false
  when ::Deepblue::InitializationConstants::HOSTNAME_TESTING
    config.deposit_context = 'testing-'
    config.download_dir = '/deepbluedata-prep/aptrust_download/'
    config.export_dir = '/deepbluedata-prep/aptrust_work/'
    config.working_dir = '/deepbluedata-prep/aptrust_work/'
  when ::Deepblue::InitializationConstants::HOSTNAME_STAGING
    config.deposit_context = 'staging-'
    config.download_dir = '/deepbluedata-prep/aptrust_download/'
    config.export_dir = '/deepbluedata-prep-new/aptrust/'
    config.working_dir = '/deepbluedata-prep-new/aptrust/'
  when ::Deepblue::InitializationConstants::HOSTNAME_TEST
    config.deposit_context = 'test-'
    config.download_dir = '/deepbluedata-prep/aptrust_download/'
    config.export_dir = '/deepbluedata-prep-new/aptrust/'
    config.working_dir = '/deepbluedata-prep-new/aptrust/'
  when ::Deepblue::InitializationConstants::HOSTNAME_LOCAL
    config.deposit_context = 'localhost-'
    config.download_dir = './data/aptrust_download/'
    config.export_dir = './data/aptrust_work/'
    config.working_dir = './data/aptrust_work/'
  else
    config.deposit_context = 'unknown-'
    config.download_dir = '/deepbluedata-prep/aptrust_download/'
    config.export_dir = '/deepbluedata-prep-new/aptrust/'
    config.working_dir = '/deepbluedata-prep-new/aptrust/'
  end

  config.aptrust_info_txt_template =<<-END_OF_TEMPLATE
Title: %title%
Access: %access%
Storage-Option: %storage_option%
Description: %description%
Item Description: %item_description%
Creator/Author: %creator%
END_OF_TEMPLATE

  config.dbd_creator              = 'Deepblue Data'
  config.dbd_bag_description      = "Bag of a %work_type% hosted at %hostname%"
  config.dbd_validate_file_checksums = true

  config.dbd_work_description =<<-END_OF_DESCRIPTION
This bag contains all of the data and metadata related to a %work_type% exported from Deepblue Data hosted at
https://deepblue.ulib.umich.edu/data/.
The data folder contains data files attached to the %work_type% (file names prefixed by the FileSet NOID),
as well as four suplemental files (file names prefixed with a 'w' and the %work_type% NOID):
a log of file exports (prefixed with the %work_type% NOID),  a metadata report,
a provenance log extract for the %work_type%, and an ingest/populate yaml-based script.
END_OF_DESCRIPTION

  rescue Exception => e
    puts e
    raise
  end
  puts "Finished Aptrust::AptrustIntegrationService"

end
