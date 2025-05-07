
Deepblue::JobTaskHelper.setup do |config|

  config.job_task_helper_debug_verbose                  = false
  config.run_job_task_debug_verbose                     = false

  # debug_verbose flags
  config.about_to_expire_embargoes_job_debug_verbose    = false
  config.abstract_rake_task_job_debug_verbose           = false
  config.deactivate_expired_embargoes_job_debug_verbose = false
  config.deepblue_job_debug_verbose                     = false
  config.globus_errors_report_job_debug_verbose         = false
  config.globus_status_report_job_debug_verbose         = false
  config.heartbeat_job_debug_verbose                    = false
  config.heartbeat_email_job_debug_verbose              = false
  config.jira_new_ticket_job_debug_verbose              = false
  config.job_helper_debug_verbose                       = false
  config.new_service_request_ticket_job_debug_verbose   = false
  config.monthly_analytics_report_job_debug_verbose     = false
  config.monthly_events_report_job_debug_verbose        = false
  config.rake_task_job_debug_verbose                    = false
  config.scheduler_start_job_debug_verbose              = false
  config.update_condensed_events_job_debug_verbose      = false
  config.works_report_job_debug_verbose                 = false

  config.allowed_job_tasks             = [ '-T', 'tmp:clean' ].freeze
  config.allowed_job_task_matching     = [ /aptrust\:[a-z_]+/,
                                           /blacklight\:delete_old_searches\[\d+\]/,
                                           /data_den\:[a-z_]+/,
                                           /deepblue\:[a-z_]+/ ].freeze
  config.job_failure_email_subscribers = [ 'fritx@umich.edu' ]

end
