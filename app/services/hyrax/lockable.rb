module Hyrax

  module Lockable

    LOCKABLE_DEBUG_VERBOSE = false

    extend ActiveSupport::Concern

    def acquire_lock_for(lock_key, &block)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "lock_key=#{lock_key}",
                                             "" ] if LOCKABLE_DEBUG_VERBOSE
      lock_manager.lock(lock_key, &block)
    end

    def lock_manager
      @lock_manager ||= lock_manager_new
    end

    def lock_manager_new
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "Hyrax.config.lock_time_to_live=#{Hyrax.config.lock_time_to_live}",
                                             "Hyrax.config.lock_retry_count=#{Hyrax.config.lock_retry_count}",
                                             "Hyrax.config.lock_retry_delay=#{Hyrax.config.lock_retry_delay}",
                                             "" ] if LOCKABLE_DEBUG_VERBOSE
      LockManager.new(
          Hyrax.config.lock_time_to_live,
          Hyrax.config.lock_retry_count,
          Hyrax.config.lock_retry_delay
      )
    end

  end

end
