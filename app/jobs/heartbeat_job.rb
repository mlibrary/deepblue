# frozen_string_literal: true

class HeartbeatJob < ::Hyrax::ApplicationJob

  HEARTBEAT_JOB_DEBUG_VERBOSE = false

  queue_as :scheduler

  def self.perform
    ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "" ] if HEARTBEAT_JOB_DEBUG_VERBOSE
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name,  event: "heartbeat" )
  end

  def perform
    ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           Deepblue::LoggingHelper.obj_class( 'class', self ),
                                           "" ] if HEARTBEAT_JOB_DEBUG_VERBOSE
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name,  event: "heartbeat" )
  end

  # def self.queue
  #   :default
  # end

end
