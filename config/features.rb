# frozen_string_literal: true

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

  feature :enable_local_analytics_ui,
          default: false,
          # description: I18n.t( "flipflop.feature_description.enable_local_analytics_ui" )
          description: "Enable local analytics access through the UI."

end
