
Aptrust::AptrustIntegrationService.setup do |config|

  config.aptrust_integration_debug_verbose = false

  config.allow_deposit            = true

  config.deposit_context          = '' # none for DBD
  config.deposit_local_repository = 'deepbluedata'

  config.clean_up_after_deposit = true
  config.clean_up_bag           = false
  config.clean_up_bag_data      = true

  config.aptrust_info_txt_template =<<-END_OF_TEMPLATE
Title: %title%
Access: %access%
Storage-Option: %storage_option%
Description: %description%
Item Description: %item_description%
Creator/Author: %creator%
END_OF_TEMPLATE

  config.default_access           = 'Institution'
  config.default_creator          = ''
  config.default_description      = 'No description.'
  config.default_item_description = 'No item description.'
  config.default_storage_option   = 'Glacier-Deep-OR'
  config.default_title            = 'No Title'

  config.dbd_creator              = 'Deepblue Data'
  config.dbd_bag_description      = "Bag of a %work_type% hosted at %hostname%"

  config.dbd_work_description =<<-END_OF_DESCRIPTION
This bag contains all of the data and metadata related to a %work_type% exported from Deepblue Data hosted at
https://deepblue.ulib.umich.edu/data/.
The data folder contains data files attached to the %work_type% (file names prefixed by the FileSet NOID),
as well as four suplemental files (file names prefixed with a 'w' and the %work_type% NOID):
a log of file exports (prefixed with the %work_type% NOID),  a metadata report,
a provenance log extract for the %work_type%, and an ingest/populate yaml-based script.
END_OF_DESCRIPTION

end
