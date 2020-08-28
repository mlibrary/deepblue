
Deepblue::JiraHelper.setup do |config|

  ## configure jira integration

  config.jira_helper_debug_verbose = true

  config.jira_integration_hostnames = [ 'deepblue.local',
                                        'testing.deepblue.lib.umich.edu',
                                        'staging.deepblue.lib.umich.edu',
                                        'deepblue.lib.umich.edu' ].freeze
  # testing jira integration is disabled
  config.jira_integration_hostnames_prod = [ 'deepblue.lib.umich.edu',
                                             'testing.deepblue.lib.umich.edu' ].freeze
  config.jira_integration_enabled = config.jira_integration_hostnames.include?( DeepBlueDocs::Application.config.hostname )
  config.jira_test_mode = !config.jira_integration_hostnames_prod.include?( DeepBlueDocs::Application.config.hostname )

  # use jira_use_authoremail_as_requester to test creation of new users in jira
  # config.jira_use_authoremail_as_requester = true if DeepBlueDocs::Application.config.hostname == 'testing.deepblue.lib.umich.edu'

  config.jira_allow_add_comment = false
  config.jira_allow_create_users = true
  config.jira_manager_project_key = 'DBHELP'
  config.jira_manager_issue_type = 'Data Deposit'
  # config.jira_manager_project_key = 'BLUEDOC'
  # config.jira_manager_issue_type = 'Story'

  config.jira_url = "#{Settings.jira.site_url}".freeze
  config.jira_rest_create_users_url = "#{config.jira_url}/jira/rest/mlibrary/1.0/users".freeze
  config.jira_rest_url = "#{config.jira_url}/jira/rest/".freeze
  config.jira_rest_api_url = "#{config.jira_url}/jira/rest/api/2/".freeze

  config.jira_field_values_discipline_map = {
      "Arts" =>
          [{
               # "self" => "#{config.jira_rest_api_url}customFieldOption/11303",
               "value" => "Arts",
               "id" => "11303"
           }],
      "Business" =>
          [{
               # "self" => "#{config.jira_rest_api_url}/customFieldOption/10820",
               "value" => "Business",
               "id" => "10820"
           }],
      "Engineering" =>
          [{
               # "self" => "#{config.jira_rest_api_url}/customFieldOption/10821",
               "value" => "Engineering",
               "id" => "10821"
           }],
      "General Information Sources" =>
          [{
               # "self" => "#{config.jira_rest_api_url}/customFieldOption/11304",
               "value" => "General Information Sources",
               "id" => "11304"
           }],
      "Government, Politics, and Law" =>
          [{
               # "self" => "#{config.jira_rest_api_url}/customFieldOption/11305",
               "value" => "Government, Politics, and Law",
               "id" => "11305"
           }],
      "Health Sciences" =>
          [{
               # "self" => "#{config.jira_rest_api_url}/customFieldOption/10822",
               "value" => "Health Sciences",
               "id" => "10822"
           }],
      "Humanities" =>
          [{
               # "self" => "#{config.jira_rest_api_url}/customFieldOption/11306",
               "value" => "Humanities",
               "id" => "11306"
           }],
      "International Studies" =>
          [{
               # "self" => "#{config.jira_rest_api_url}/customFieldOption/11307",
               "value" => "International Studies",
               "id" => "11307"
           }],
      "News and Current Events" =>
          [{
               # "self" => "#{config.jira_rest_api_url}/customFieldOption/11308",
               "value" => "News and Current Events",
               "id" => "11308"
           }],
      "Science" =>
          [{
               # "self" => "#{config.jira_rest_api_url}/customFieldOption/10824",
               "value" => "Science",
               "id" => "10824"
           }],
      "Social Sciences" =>
          [{
               # "self" => "#{config.jira_rest_api_url}/customFieldOption/10825",
               "value" => "Social Sciences",
               "id" => "10825"
           }],
      "Other" =>
          [{
               # "self" => "#{config.jira_rest_api_url}/customFieldOption/10823",
               "value" => "Other",
               "id" => "10823"
           }]
  }.freeze


end
