
# This doesn't seem to do anything
[ :after_create_concern,
  :after_create_fileset,
  :after_update_content,
  :after_revert_content,
  :after_update_metadata,
  :after_import_local_file_success,
  :after_import_local_file_failure,
  :after_fixity_check_failure,
  :after_destroy,
  :after_import_url_success,
  :after_import_url_failure
].each do |event_name|

  Deepblue::LoggingService.new event_name: event_name

end