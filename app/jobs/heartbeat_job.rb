# frozen_string_literal: true

class HeartbeatJob < ::Deepblue::DeepblueJob

  mattr_accessor :heartbeat_job_debug_verbose
  @@heartbeat_job_debug_verbose = ::Deepblue::JobTaskHelper.heartbeat_job_debug_verbose

  include JobHelper # see JobHelper for :email_targets, :hostname, :job_msg_queue, :timestamp_begin, :timestamp_end
  queue_as :scheduler

  # bundle exec rake deepblue:run_job['{"job_class":"HeartBeat"\,"verbose":true}']

  def self.perform( *args )
    HeartbeatJob.perform_now( *args )
  end

  def perform( *args )
    job_status_init
    timestamp_begin
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "args=#{args}",
                                           "" ] if heartbeat_job_debug_verbose
    options = ::Deepblue::JobTaskHelper.initialize_options_from( args )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "options=#{options}",
                                           "" ] if heartbeat_job_debug_verbose
    verbose = job_options_value(options, key: 'verbose', default_value: false )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "verbose=#{verbose}",
                                           "" ] if heartbeat_job_debug_verbose
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name,  event: "heartbeat" )
    job_status.finished!
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: args )
    raise e
  end

end
