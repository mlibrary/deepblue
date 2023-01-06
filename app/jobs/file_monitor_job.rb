# frozen_string_literal: true

# bundle exec rake deepblue:run_job['{"job_class":"HeartBeat"\,"verbose":true}']
class FileMonitorJob < ::Deepblue::DeepblueJob

  mattr_accessor :file_monitor_job_debug_verbose, default: false
  @@bold_puts = false

  def perform( file_path:, wait_duration: 1, wait_for: )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "file_path=#{file_path}",
                                           "wait_duration=#{wait_duration}",
                                           "wait_for=#{wait_for}",
                                           "" ], bold_puts: @@bold_puts if file_monitor_job_debug_verbose
    wait_duration ||= 1
    wait_duration = 1 if wait_duration < 1
    if 'is_deleted' == wait_for
      while File.exist? file_path do
        sleep wait_duration
      end
      puts "#{file_path} was deleted."
    elsif 'to_exist' == wait_for
      while !File.exist? file_path do
        sleep wait_duration
      end
      puts "#{file_path} exists."
    else
      while !File.exist? file_path do
        sleep wait_duration
      end
      puts "#{file_path} exists."
    end
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: { file_path: file_path, wait_for: wait_for  } )
    raise e
  end

end
