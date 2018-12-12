Flipflop.configure do
  feature :only_use_data_set_work_type,
          default: true,
          description: "Only give users ability to create Data Set Work Type"

  feature :limit_browse_options,
          default: true,
          description: "Limit the users browse options"

  feature :dir_upload,
          default: false,
          description: "Allow user to upload files for work from a directory."           

end
