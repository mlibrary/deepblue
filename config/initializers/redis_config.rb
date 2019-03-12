require 'redis'
Redis.current = Redis.new(Settings.redis.to_h)
