
SCHEDULER_INTEGRATION_SERVICE_DEBUG_VERBOSE = true

Deepblue::SchedulerIntegrationService.setup do |config|
  puts "Starting scheduler integration service configuration..." if SCHEDULER_INTEGRATION_SERVICE_DEBUG_VERBOSE
  config.scheduler_integration_service_debug_verbose = false

  # scheduler log config
  config.scheduler_heartbeat_email_targets = [ 'fritx@umich.edu' ].freeze # leave empty to disable
  config.scheduler_log_echo_to_rails_logger = true
  config.scheduler_start_job_default_delay = 5.minutes.to_i
  config.scheduler_active = false

  config.scheduler_job_file_path = Rails.application.root.join( 'data', 'scheduler', 'scheduler_jobs.yml' )
  puts "scheduler_job_file_path=#{config.scheduler_job_file_path}" if SCHEDULER_INTEGRATION_SERVICE_DEBUG_VERBOSE

  program_name = Rails.configuration.program_name
  puts "program_name=#{program_name}" if SCHEDULER_INTEGRATION_SERVICE_DEBUG_VERBOSE
  if program_name == 'rails' || program_name == 'puma'
    puts "Rails.configuration.hostname=#{Rails.configuration.hostname}" if SCHEDULER_INTEGRATION_SERVICE_DEBUG_VERBOSE

    case Rails.configuration.hostname
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

    config.scheduler_active = ( config.scheduler_active && File.exists?( config.scheduler_job_file_path ) )

    # SchedulerStartJob.perform_later( job_delay: 20.seconds.to_i, restart: true ) if config.scheduler_active
    # SchedulerStartJob.perform_later( job_delay: config.scheduler_start_job_default_delay, restart: true ) if config.scheduler_active

  end
  ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                         ::Deepblue::LoggingHelper.called_from,
                                         "config.scheduler_active=#{config.scheduler_active}",
                                         "" ] if SCHEDULER_INTEGRATION_SERVICE_DEBUG_VERBOSE

  config.scheduler_autostart_servers = [ 'testing.deepblue.lib.umich.edu',
                                         'staging.deepblue.lib.umich.edu',
                                         'deepblue.lib.umich.edu' ].freeze

  # config.scheduler_autostart_emails = [ 'fritx@umich.edu', 'blancoj@umich.edu' ].freeze
  config.scheduler_autostart_emails = [ 'fritx@umich.edu' ].freeze
  puts "Finished scheduler integration service configuration." if SCHEDULER_INTEGRATION_SERVICE_DEBUG_VERBOSE
end
