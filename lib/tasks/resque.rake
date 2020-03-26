# frozen_string_literal: true

require 'resque/tasks'
require 'resque/scheduler/tasks'
require 'resque/pool/tasks'

# This provides access to the Rails env within all Resque workers
# This is required so that the eager_load_paths can be found in autoload_paths
# task 'resque:setup' => :environment
task "resque:setup" => :environment do
  ENV['QUEUE'] = "*"
end

# Set up resque-pool parent process
task 'resque:pool:setup' do
  ActiveRecord::Base.connection.disconnect!
  Resque::Pool.after_prefork do |_job|
    ActiveRecord::Base.establish_connection
    Resque.redis.client.reconnect
  end
end

namespace :resque do

  task :setup_schedule => :setup do
    require 'resque-scheduler'
    require 'active_scheduler'
    Resque::Scheduler.dynamic = true
    Deepblue::SchedulerHelper.log( class_name: self.class.name,
                                   event: "setup_schedule",
                                   scheduler_job_file: ::Deepblue::SchedulerIntegrationService.scheduler_job_file )
    # Resque.schedule = YAML.load_file Rails.root.join( 'config', ::Deepblue::SchedulerIntegrationService.scheduler_job_file )
    yaml_schedule    = YAML.load_file( Rails.root.join( 'config', ::Deepblue::SchedulerIntegrationService.scheduler_job_file ) ) || {}
    wrapped_schedule = ActiveScheduler::ResqueWrapper.wrap yaml_schedule
    Resque.schedule  = wrapped_schedule
  end

  task :scheduler => :setup_schedule
end
