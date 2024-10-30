# frozen_string_literal: true

require_relative './verify_task'

namespace :aptrust do

  # bundle exec rake aptrust:verify
  # bundle exec rake aptrust:verify['{"verbose":true\,"test_mode":true}']
  # bundle exec rake aptrust:verify['{"verbose":true\,"test_mode":true}']
  desc 'Verify upload from status table.'
  task :verify, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = ::Aptrust::VerifyTask.new( options: args[:options] )
    task.run
  end

end
