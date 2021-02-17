# frozen_string_literal: true


# bundle exec rake deepblue:run_job['{"job_class":"HeartBeat"\,"verbose":true}']
class HeartbeatJob < ::Deepblue::DeepblueJob

  mattr_accessor :heartbeat_job_debug_verbose
  @@heartbeat_job_debug_verbose = ::Deepblue::JobTaskHelper.heartbeat_job_debug_verbose

  queue_as :scheduler

  def self.perform( *args )
    HeartbeatJob.perform_now( *args )
  end

  def perform( *args )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "args=#{args}",
                                           "" ] if heartbeat_job_debug_verbose
    initialize_options_from( *args, debug_verbose: heartbeat_job_debug_verbose )
    # NOTE: the point of this job is to write to the log
    log( event: "heartbeat" )
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: args )
    raise e
  end

end
