# frozen_string_literal: true

class HeartbeatJob < ::Hyrax::ApplicationJob

  HEARTBEAT_JOB_DEBUG_VERBOSE = ::Deepblue::JobTaskHelper.heartbeat_job_debug_verbose

  include JobHelper
  queue_as :scheduler

  # bundle exec rake deepblue:run_job['{"job_class":"HeartBeat"\,"verbose":true}']

  def self.perform( *args )
    HeartbeatJob.perform_now( *args )
  end

  def perform( *args )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "args=#{args}",
                                           "" ] if true || HEARTBEAT_JOB_DEBUG_VERBOSE
    options = ::Deepblue::JobTaskHelper.initialize_options_from( args )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "options=#{options}",
                                           "" ] if true || HEARTBEAT_JOB_DEBUG_VERBOSE
    verbose = job_options_value(options, key: 'verbose', default_value: false )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "verbose=#{verbose}",
                                           "" ] if true || HEARTBEAT_JOB_DEBUG_VERBOSE
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name,  event: "heartbeat" )
  end

  # def self.queue
  #   :default
  # end

end
