module Hyrax

  module Actors

    # This is always the last middleware on the actor middleware stack.
    class Terminator

      mattr_accessor :actors_terminator_debug_verbose,
                     default: ::DeepBlueDocs::Application.config.actors_terminator_debug_verbose

      def create(env)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "env=#{env}",
                                               "" ] if actors_terminator_debug_verbose
        true
      end

      def update(env)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "env=#{env}",
                                               "" ] if actors_terminator_debug_verbose
        true
      end

      def destroy(env)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "env=#{env}",
                                               "" ] if actors_terminator_debug_verbose
        true
      end

    end

  end

end
