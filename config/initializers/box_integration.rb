
Deepblue::BoxIntegrationService.setup do |config|

  config.box_enabled = false
  config.box_developer_token = nil # replace this with a developer token to override Single Auth
  # config.box_developer_token = '<deleted>'.freeze
  config.box_dlib_dbd_box_user_id = '3200925346'
  config.box_ulib_dbd_box_id = '45101723215'
  config.box_verbose = true
  config.box_always_report_not_logged_in_errors = true
  config.box_create_dirs_for_empty_works = true
  config.box_access_and_refresh_token_file = Rails.root.join( 'config', 'box_config.yml' ).freeze
  config.box_access_and_refresh_token_file_init = Rails.root.join( 'config', 'box_config_init.yml' ).freeze
  config.box_integration_enabled = config.box_enabled && ( !config.box_developer_token.nil? ||
      File.exist?( config.box_access_and_refresh_token_file ) )

end
