# frozen_string_literal: true

class ResolrizeJob < ::Deepblue::DeepblueJob

  mattr_accessor :resolrize_job_debug_verbose,
                 default: ::Deepblue::JobTaskHelper.resolrize_job_debug_verbose

SCHEDULER_ENTRY = <<-END_OF_SCHEDULER_ENTRY

resolrize_job:
  # Run on demand
  #      M H D
  # cron: '*/5 * * * *'
  cron: '25 5 * * *'
  class: ResolrizeJob
  queue: scheduler
  description: Reset the condensed events job.
  args:
    hostnames:
      - 'deepblue.lib.umich.edu'
      - 'staging.deepblue.lib.umich.edu'
      - 'testing.deepblue.lib.umich.edu'
    quiet: true
    by_request_only: true
    subscription_service_id: resolrize_job         

END_OF_SCHEDULER_ENTRY

  queue_as :scheduler

  def perform( *args )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "args=#{args}",
                                           "" ] if resolrize_job_debug_verbose
    initialize_options_from( *args, debug_verbose: resolrize_job_debug_verbose )
    return job_finished unless hostname_allowed?
    job_msg_queue << "Start processing at #{DateTime.now}"
    log( event: "resolrize job", hostname_allowed: hostname_allowed? )
    is_quiet?
    ActiveFedora::Base.reindex_everything2( logger: Rails.logger,
                                            job_msg_queue: job_msg_queue,
                                            debug_verbose: resolrize_job_debug_verbose )
    job_msg_queue << "Finished processing at #{DateTime.now}"
    email_results
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: args )
    email_failure( task_name: self.class.name, exception: e, event: self.class.name )
    raise
  end
  
end
