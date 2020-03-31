
Deepblue::UptimeService.setup do |config|

  config.load_timestamp = DeepBlueDocs::Application.config.load_timestamp
  config.program_name = DeepBlueDocs::Application.config.program_name

  begin
    Dir.mkdir( config.uptime_dir ) unless Dir.exists? config.uptime_dir
  rescue Exception => e # rubocop:disable Lint/RescueException
    # ignore, this will happen during moku build and deployment
  end

  config.uptime_timestamp_file_write

end
