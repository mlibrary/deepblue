require 'resque'
# We make another client here with the same options as Redis.current, though
# we may be able to use it directly.
Resque.redis = Redis.new(Settings.redis.to_h)
Resque.redis.namespace = Settings.hyrax.redis_namespace
Resque.inline = Rails.env.test?
