
Deepblue::SchedulerIntegrationService.setup do |config|

  # scheduler log config
  config.scheduler_heartbeat_email_targets = [ 'fritx@umich.edu' ].freeze # leave empty to disable
  config.scheduler_job_file = 'scheduler_jobs_prod.yml'
  config.scheduler_log_echo_to_rails_logger = true
  config.scheduler_start_job_default_delay = 5.minutes

  # TODO:
  case DeepBlueDocs::Application.config.hostname
  when ::Deepblue::InitializationConstants::HOSTNAME_PROD
    config.scheduler_active = true
  when ::Deepblue::InitializationConstants::HOSTNAME_TESTING
    config.scheduler_active = true
  when ::Deepblue::InitializationConstants::HOSTNAME_STAGING
    config.scheduler_active = true
  when ::Deepblue::InitializationConstants::HOSTNAME_TEST
    config.scheduler_active = false
  when ::Deepblue::InitializationConstants::HOSTNAME_LOCAL
    config.scheduler_active = false
  else
    config.scheduler_active = false
  end

  SchedulerStartJob.perform_later( job_delay: 20.seconds, restart: true ) if config.scheduler_active
  # SchedulerStartJob.perform_later( job_delay: config.scheduler_start_job_default_delay, restart: true ) if config.scheduler_active

end
