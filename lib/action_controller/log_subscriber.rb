
# monkey override actionpack lib/action_controller/log_subscriber.rb
require File.join(Gem::Specification.find_by_name("actionpack").full_gem_path, "lib/action_controller/log_subscriber.rb")

module ActionController

  class LogSubscriber

    ACTION_CONTROLLER_LOG_SUBSCRIBER_DEBUG_VERBOSE = false # monkey

    alias_method :monkey_start_processing, :start_processing

    def start_processing(event)
      # begin monkey
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if ACTION_CONTROLLER_LOG_SUBSCRIBER_DEBUG_VERBOSE # + caller_locations(1,40)
      # end monkey

      monkey_start_processing( event )

      # begin monkey
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if ACTION_CONTROLLER_LOG_SUBSCRIBER_DEBUG_VERBOSE # + caller_locations(1,40)
      # end monkey
    end

  end

end
