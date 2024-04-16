# frozen_string_literal: true

require_relative './reupload_task'

namespace :aptrust do

  # bundle exec rake aptrust:reupload
  # bundle exec rake aptrust:reupload['{"verbose":true\,"test_mode":true}']
  # bundle exec rake aptrust:reupload['{"verbose":true\,"event":"deposit_failed"\,"test_mode":true}']
  # bundle exec rake aptrust:reupload['{"verbose":true\,"test_mode":true\,"max_size":"1_000_000"}']
  # bundle exec rake aptrust:reupload['{"verbose":true\,"test_mode":true\,"max_uploads":1}']
  # bundle exec rake aptrust:reupload['{"date_end":"2024/03/22 00:00:00"}']
  # bundle exec rake aptrust:reupload['{"date_begin":"2024/03/01 00:00:00"\,"date_end":"2024/03/22 00:00:00"}']
  # bundle exec rake aptrust:reupload['{"date_end":"2024/03/22 00:00:00"\,"max_size":"1_000_000"\,"event":"failed"\,"verbose":true}']
  # bundle exec rake aptrust:reupload['{"verbose":true\,"quiet":false}']
  # bundle exec rake aptrust:reupload['{"verbose":true\,"debug_verbose":true}']
  # bundle exec rake aptrust:reupload['{"quiet":true}']
  desc 'Upload to APTrust by list of noids'
  task :reupload, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = ::Aptrust::ReuploadTask.new( options: args[:options] )
    task.run
  end

end
