
Deepblue::UptimeService.setup do |config|

  # puts "DeepBlueDocs::Application.config.program_name=#{DeepBlueDocs::Application.config.program_name}"
  # puts "ARGV=#{ARGV}"
  # puts "DeepBlueDocs::Application.config.program_args=#{DeepBlueDocs::Application.config.program_args}"
  config.program_arg1 = DeepBlueDocs::Application.config.program_args.first

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
