
Deepblue::JobTaskHelper.setup do |config|

  config.job_task_helper_debug_verbose = true
  config.run_job_task_debug_verbose = true

  # debug_verbose flags
  config.about_to_expire_embargoes_job_debug_verbose = false
  config.abstract_rake_task_job_debug_verbose = true
  config.characterize_job_debug_verbose = false
  config.deactivate_expired_embargoes_job_debug_verbose = false
  config.heartbeat_job_debug_verbose = false
  config.heartbeat_email_job_debug_verbose = false
  config.ingest_job_debug_verbose = false
  config.rake_task_job_debug_verbose = true
  config.works_report_job_debug_verbose = false

  config.allowed_job_tasks = [ "-T", "tmp:clear" ].freeze

end
