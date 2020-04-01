
Deepblue::JiraHelper.setup do |config|

  ## configure jira integration
  config.jira_integration_hostnames = [ 'deepblue.local',
                                        'testing.deepblue.lib.umich.edu',
                                        'staging.deepblue.lib.umich.edu',
                                        'deepblue.lib.umich.edu' ].freeze
  config.jira_integration_hostnames_prod = [ 'deepblue.lib.umich.edu' ].freeze
  config.jira_integration_enabled = config.jira_integration_hostnames.include?( DeepBlueDocs::Application.config.hostname )
  config.jira_test_mode = !config.jira_integration_hostnames_prod.include?( DeepBlueDocs::Application.config.hostname )
  config.jira_allow_create_users = true
  config.jira_manager_project_key = 'DBHELP'
  config.jira_manager_issue_type = 'Data Deposit'
  # config.jira_manager_project_key = 'BLUEDOC'
  # config.jira_manager_issue_type = 'Story'

end
