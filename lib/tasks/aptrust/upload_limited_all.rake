# frozen_string_literal: true

require_relative './upload_limited_all_task'

namespace :aptrust do

  # bundle exec rake aptrust:upload_limited_all
  desc 'APTrust upload limited all.'
  task :upload_limited_all, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = ::Aptrust::UploadLimitedAllTask.new( options: args[:options] )
    task.run
  end

end
