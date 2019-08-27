# frozen_string_literal: true

class HeartbeatJob < ::Hyrax::ApplicationJob
  queue_as :scheduler

  def self.perform
    ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "" ]
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name,  event: "heartbeat" )
  end

  def perform
    ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           Deepblue::LoggingHelper.obj_class( 'class', self ),
                                           "" ]
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name,  event: "heartbeat" )
  end

  # def self.queue
  #   :default
  # end

end
