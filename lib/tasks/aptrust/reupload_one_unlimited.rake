# frozen_string_literal: true

require_relative './reupload_one_unlimited_task'

namespace :aptrust do

  # bundle exec rake aptrust:reupload_one_unlimited
  # bundle exec rake aptrust:reupload_one_unlimited['{"test_mode":true}']
  desc 'APTrust reupload limiting size of works uploaded.'
  task :reupload_one_unlimited, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = ::Aptrust::ReuploadOneUnlimitedTask.new( options: args[:options] )
    task.run
  end

end
