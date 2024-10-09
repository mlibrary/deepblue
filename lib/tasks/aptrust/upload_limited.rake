# frozen_string_literal: true

require_relative './upload_limited_task'

namespace :aptrust do

  # bundle exec rake aptrust:upload_limited
  desc 'APTrust upload limiting size of works uploaded.'
  task :upload_limited, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = ::Aptrust::UploadLimitedTask.new( options: args[:options] )
    task.run
  end

end
