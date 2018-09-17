require 'resque'
config = YAML.load(ERB.new(IO.read(File.join(Rails.root, 'config', 'redis.yml'))).result)[Rails.env].with_indifferent_access
Resque.redis = Redis.new(host: config[:host], port: config[:port], thread_safe: true)

Resque.inline = Rails.env.test?
#Resque.redis.namespace = "#{CurationConcerns.config.redis_namespace}:#{Rails.env}"

Hyrax.config.redis_namespace = Settings.redis_namespace || 'umrdr_redis_namespace_needs_configuration'
Resque.redis.namespace = Settings.redis_namespace       || 'umrdr_redis_namespace_needs_configuration'
