# frozen_string_literal: true

Ezid::Client.configure do |config|
  config.host     = ENV['EZID_HOST'] || Settings.ezid.host
  config.port     = ENV['EZID_PORT'] || Settings.ezid.port
  config.user     = ENV['EZID_USER'] || Settings.ezid.user
  config.password = ENV['EZID_PASSWORD'] || Settings.ezid.password
  config.timeout  = ENV['EZID_TIMEOUT'] || Settings.ezid.timeout
  config.default_shoulder = ENV['EZID_DEFAULT_SHOULDER'] || Settings.ezid.shoulder
end
