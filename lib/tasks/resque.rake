# frozen_string_literal: true

# TODO: what gem does this come from
require 'resque/pool/tasks'

# This provides access to the Rails env within all Resque workers
# This is required so that the eager_load_paths can be found in autoload_paths
task 'resque:setup' => :environment

# Set up resque-pool parent process
task 'resque:pool:setup' do
  ActiveRecord::Base.connection.disconnect!
  Resque::Pool.after_prefork do |_job|
    ActiveRecord::Base.establish_connection
    Resque.redis.client.reconnect
  end
end
