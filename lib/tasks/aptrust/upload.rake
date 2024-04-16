# frozen_string_literal: true

require_relative './upload_task'

namespace :aptrust do

  # bundle exec rake aptrust:upload
  # bundle exec rake aptrust:upload['{"verbose":true\,"test_mode":true}']
  # bundle exec rake aptrust:upload['{"verbose":true\,"test_mode":true\,"max_size":"1_000_000"}']
  # bundle exec rake aptrust:upload['{"verbose":true\,"test_mode":true\,"max_uploads":1}']
  # bundle exec rake aptrust:upload['{"verbose":true\,"test_mode":true\,"date_end":"2024/03/22 00:00:00"}']
  # bundle exec rake aptrust:upload['{"verbose":true\,"test_mode":true\,"date_begin":"2024/03/22 00:00:00"}']
  # bundle exec rake aptrust:upload['{"date_end":"2024/03/22 00:00:00"}']
  # bundle exec rake aptrust:upload['{"date_begin":"2024/03/01 00:00:00"\,"date_end":"2024/03/22 00:00:00"}']
  # bundle exec rake aptrust:upload['{"date_end":"2024/03/22 00:00:00"\,"max_size":"1_000_000"\,"event":"failed"\,"verbose":true}']
  # bundle exec rake aptrust:upload['{"verbose":true\,"quiet":false}']
  # bundle exec rake aptrust:upload['{"verbose":true\,"debug_verbose":true}']
  # bundle exec rake aptrust:upload['{"quiet":true}']
  desc 'Upload to APTrust by list of noids'
  task :upload, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = ::Aptrust::UploadTask.new( options: args[:options] )
    task.run
  end

end
