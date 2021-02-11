# frozen_string_literal: true

class HeartbeatEmailJob < ::Hyrax::ApplicationJob

  HEARTBEAT_EMAIL_JOB_DEBUG_VERBOSE = ::Deepblue::JobTaskHelper.heartbeat_email_job_debug_verbose

SCHEDULER_ENTRY = <<-END_OF_SCHEDULER_ENTRY

heartbeat_email_job:
  # Run once a day, one minute after midnight (which is offset by 4 or [5 during daylight savings time], due to GMT)
  #      M H
  # cron: '*/5 * * * *'
  cron: '1 5 * * *'
  # rails_env: production
  class: HeartbeatEmailJob
  queue: scheduler
  description: Heartbeat email job.
  args:
    hostnames:
      - 'deepblue.lib.umich.edu'
      # - 'staging.deepblue.lib.umich.edu'
      # - 'testing.deepblue.lib.umich.edu'
    subscription_service_id: heartbeat_email_job

END_OF_SCHEDULER_ENTRY

  include JobHelper # see JobHelper for :email_targets, :hostname, :job_msg_queue, :timestamp_begin, :timestamp_end
  queue_as :scheduler

  attr_accessor :hostnames, :options, :subscription_service_id, :verbose

  def self.perform( *args )
    HeartbeatEmailJob.perform_now( *args )
  end

  def perform( *args )
    job_status_init
    timestamp_begin
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if HEARTBEAT_EMAIL_JOB_DEBUG_VERBOSE
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name, event: "heartbeat email" )
    ::Deepblue::JobTaskHelper.has_options( *args, job: self, debug_verbose: HEARTBEAT_EMAIL_JOB_DEBUG_VERBOSE )
    ::Deepblue::JobTaskHelper.is_verbose( job: self, debug_verbose: HEARTBEAT_EMAIL_JOB_DEBUG_VERBOSE )
    return unless ::Deepblue::JobTaskHelper.hostname_allowed( job: self, debug_verbose: HEARTBEAT_EMAIL_JOB_DEBUG_VERBOSE )
    self.email_targets = self.email_targets + ::Deepblue::SchedulerIntegrationService.scheduler_heartbeat_email_targets.dup
    ::Deepblue::JobTaskHelper.has_email_targets( job: self, debug_verbose: HEARTBEAT_EMAIL_JOB_DEBUG_VERBOSE )
    self.email_targets.each do |email_target|
       ::Deepblue::JobTaskHelper.send_email( email_target: email_target,
                                             task_name: "scheduler heartbeat",
                                             event: "Heartbeat email" )
    end
    job_status.finished!
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: args )
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

end
