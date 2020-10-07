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

END_OF_SCHEDULER_ENTRY

  include JobHelper
  queue_as :scheduler

  def self.perform( *args )
    HeartbeatEmailJob.perform_now( *args )
  end

  def perform( *args )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "args=#{args}",
                                           "" ] if HEARTBEAT_EMAIL_JOB_DEBUG_VERBOSE
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name, event: "heartbeat email" )
    options = {}
    args.each { |key,value| options[key] = value }
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           "options=#{options}",
                                           ::Deepblue::LoggingHelper.obj_class( 'options', options ),
                                           "" ] if HEARTBEAT_EMAIL_JOB_DEBUG_VERBOSE
    verbose = job_options_value(options, key: 'verbose', default_value: false )
    ::Deepblue::LoggingHelper.debug "verbose=#{verbose}" if verbose
    hostnames = job_options_value(options, key: 'hostnames', default_value: [], verbose: verbose )
    hostname = ::DeepBlueDocs::Application.config.hostname
    return unless hostnames.include? hostname
    ::Deepblue::SchedulerIntegrationService.scheduler_heartbeat_email_targets.each do |email_target|
       ::Deepblue::JobTaskHelper.send_email( email_target: email_target,
                                             task_name: "scheduler heartbeat",
                                             event: "Heartbeat email" )
    end
  rescue Exception => e # rubocop:disable Lint/RescueException
    Rails.logger.error "#{e.class} #{e.message} at #{e.backtrace[0]}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

end
