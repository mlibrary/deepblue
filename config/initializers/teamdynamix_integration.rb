
Deepblue::TeamdynamixHelper.setup do |config|

  ## configure teamdynamix integration

  config.teamdynamix_helper_debug_verbose = false
  config.tdx_helper_debug_verbose = false

  config.tdx_integration_hostnames = [ 'deepblue.local',
                                       'testing.deepblue.lib.umich.edu',
                                       'staging.deepblue.lib.umich.edu',
                                       'deepblue.lib.umich.edu' ].freeze
  # testing tdx integration is disabled
  config.tdx_integration_hostnames_prod = [ 'deepblue.lib.umich.edu',
                                            'disabled.testing.deepblue.lib.umich.edu' ].freeze
  config.tdx_integration_enabled = config.tdx_integration_hostnames.include?( Rails.configuration.hostname )
  config.tdx_test_mode = !config.tdx_integration_hostnames_prod.include?( Rails.configuration.hostname )

  # use tdx_use_authoremail_as_requester to test creation of new users in tdx
  # config.tdx_use_authoremail_as_requester = true if Rails.configuration.hostname == 'testing.deepblue.lib.umich.edu'

  config.tdx_allow_add_comment = false
  config.tdx_allow_create_users = true
  config.tdx_manager_project_key = 'DBHELP'
  config.tdx_manager_issue_type = 'Data Deposit'
  # config.tdx_manager_project_key = 'BLUEDOC'
  # config.tdx_manager_issue_type = 'Story'

  # config.tdx_url = "#{Settings.tdx.site_url}".freeze
  # config.tdx_rest_create_users_url = "#{config.tdx_url}/tdx/rest/mlibrary/1.0/users".freeze
  # config.tdx_rest_url = "#{config.tdx_url}/tdx/rest/".freeze
  # config.tdx_rest_api_url = "#{config.tdx_url}/tdx/rest/api/2/".freeze

  config.tdx_field_values_discipline_map = {
      "Arts" =>
          [{
               # "self" => "#{config.tdx_rest_api_url}customFieldOption/11303",
               "value" => "Arts",
               "id" => "11303"
           }],
      "Business" =>
          [{
               # "self" => "#{config.tdx_rest_api_url}/customFieldOption/10820",
               "value" => "Business",
               "id" => "10820"
           }],
      "Engineering" =>
          [{
               # "self" => "#{config.tdx_rest_api_url}/customFieldOption/10821",
               "value" => "Engineering",
               "id" => "10821"
           }],
      "General Information Sources" =>
          [{
               # "self" => "#{config.tdx_rest_api_url}/customFieldOption/11304",
               "value" => "General Information Sources",
               "id" => "11304"
           }],
      "Government, Politics, and Law" =>
          [{
               # "self" => "#{config.tdx_rest_api_url}/customFieldOption/11305",
               "value" => "Government, Politics, and Law",
               "id" => "11305"
           }],
      "Health Sciences" =>
          [{
               # "self" => "#{config.tdx_rest_api_url}/customFieldOption/10822",
               "value" => "Health Sciences",
               "id" => "10822"
           }],
      "Humanities" =>
          [{
               # "self" => "#{config.tdx_rest_api_url}/customFieldOption/11306",
               "value" => "Humanities",
               "id" => "11306"
           }],
      "International Studies" =>
          [{
               # "self" => "#{config.tdx_rest_api_url}/customFieldOption/11307",
               "value" => "International Studies",
               "id" => "11307"
           }],
      "News and Current Events" =>
          [{
               # "self" => "#{config.tdx_rest_api_url}/customFieldOption/11308",
               "value" => "News and Current Events",
               "id" => "11308"
           }],
      "Science" =>
          [{
               # "self" => "#{config.tdx_rest_api_url}/customFieldOption/10824",
               "value" => "Science",
               "id" => "10824"
           }],
      "Social Sciences" =>
          [{
               # "self" => "#{config.tdx_rest_api_url}/customFieldOption/10825",
               "value" => "Social Sciences",
               "id" => "10825"
           }],
      "Other" =>
          [{
               # "self" => "#{config.tdx_rest_api_url}/customFieldOption/10823",
               "value" => "Other",
               "id" => "10823"
           }]
  }.freeze

end
