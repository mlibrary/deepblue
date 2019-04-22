require 'redlock'

module Hyrax

  class LockManager

    class UnableToAcquireLockError < StandardError; end

    attr_reader :client

    # @param [Fixnum] time_to_live How long to hold the lock in milliseconds
    # @param [Fixnum] retry_count How many times to retry to acquire the lock before raising UnableToAcquireLockError
    # @param [Fixnum] retry_delay Maximum wait time in milliseconds before retrying. Wait time is a random value between 0 and retry_delay.
    def initialize( time_to_live, retry_count, retry_delay )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "time_to_live=#{time_to_live}",
                                             "retry_count=#{retry_count}",
                                             "retry_delay=#{retry_delay}",
                                             "servers=#{[Redis.current]}",
                                             "" ]
      @ttl = time_to_live
      @client = Redlock::Client.new([Redis.current], retry_count: retry_count, retry_delay: retry_delay)
    end

    # Blocks until lock is acquired or timeout.
    def lock(key)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "@ttl=#{@ttl}",
                                             "@client=#{@client}",
                                             "key=#{key}",
                                             "" ]
      returned_from_block = nil
      client.lock(key, @ttl) do |locked|
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "locked=#{locked}",
                                               "" ]
        raise UnableToAcquireLockError unless locked
        returned_from_block = yield
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "yield successful",
                                               "" ]
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "returned_from_block=#{returned_from_block}",
                                             "" ]
      returned_from_block
    end

  end

end
