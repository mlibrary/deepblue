# frozen_string_literal: true

require_relative './reupload_modified_task'

namespace :aptrust do

  # bundle exec rake aptrust:reupload_modified
  # bundle exec rake aptrust:reupload_modified['{"verbose":true\,"test_mode":true}']
  # bundle exec rake aptrust:reupload_modified['{"verbose":true\,"test_mode":true\,"max_size":"1_000_000"}']
  # bundle exec rake aptrust:reupload_modified['{"verbose":true\,"test_mode":true\,"max_uploads":1}']
  desc 'Upload APTrust by last modified date'
  task :reupload_modified, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = ::Aptrust::ReuploadModifiedTask.new( options: args[:options] )
    task.run
  end

end
