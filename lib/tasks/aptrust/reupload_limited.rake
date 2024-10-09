# frozen_string_literal: true

require_relative './reupload_limited_task'

namespace :aptrust do

  # bundle exec rake aptrust:reupload_limited
  desc 'APTrust reupload limiting size of works uploaded.'
  task :reupload_limited, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = ::Aptrust::ReuploadLimitedTask.new( options: args[:options] )
    task.run
  end

end
