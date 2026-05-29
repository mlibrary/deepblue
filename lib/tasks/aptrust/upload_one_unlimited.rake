# frozen_string_literal: true

require_relative './upload_one_unlimited_task'

namespace :aptrust do

  # bundle exec rake aptrust:upload_one_unlimited
  # bundle exec rake aptrust:upload_one_unlimited['{"test_mode":true}']
  desc 'APTrust upload one unlimited (min data set size 1TB).'
  task :upload_one_unlimited, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = ::Aptrust::UploadOneUnlimitedTask.new( options: args[:options] )
    task.run
  end

end
