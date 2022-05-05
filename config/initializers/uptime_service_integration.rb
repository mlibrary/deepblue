
Deepblue::UptimeService.setup do |config|

  # puts "Rails.configuration.program_name=#{Rails.configuration.program_name}"
  # puts "ARGV=#{ARGV}"
  # puts "Rails.configuration.program_args=#{Rails.configuration.program_args}"
  config.program_arg1 = Rails.configuration.program_args.first

  if config.is_rake?
    # puts "is_rake? #{config.is_rake?}"
    # puts "config.program_arg1=#{config.program_arg1}"
    # strip args down to leading rake task name
    if config.program_arg1 =~ /^([^\[]+)\[?.*$/
      task_name = Regexp.last_match(1)
      config.program_arg1 = task_name.gsub( /[^a-z0-9\-]+/i, '-' )
    end
  end

  begin
    Dir.mkdir( config.uptime_dir ) unless Dir.exists? config.uptime_dir
  rescue Exception => e # rubocop:disable Lint/RescueException
    # ignore, this will happen during moku build and deployment
  end

  config.uptime_timestamp_file_write

end
