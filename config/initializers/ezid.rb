# frozen_string_literal: true

Ezid::Client.configure do |config|
  # Decide whether to use SSL -- default to true
  # ENV always applies if present, must be "false" to disable
  # If ENV is not present, Settings.use_ssl must be false or "false" to disable
  env = ENV['EZID_USE_SSL']
  use_ssl = if env
              env.to_s != 'false'
            else
              Settings.ezid.use_ssl.to_s != 'false'
            end

  config.host     = ENV['EZID_HOST'] || Settings.ezid.host
  config.port     = ENV['EZID_PORT'] || Settings.ezid.port
  config.use_ssl  = use_ssl
  config.user     = ENV['EZID_USER'] || Settings.ezid.user
  config.password = ENV['EZID_PASSWORD'] || Settings.ezid.password
  config.timeout  = ENV['EZID_TIMEOUT'] || Settings.ezid.timeout
  config.default_shoulder = ENV['EZID_DEFAULT_SHOULDER'] || Settings.ezid.shoulder
end
