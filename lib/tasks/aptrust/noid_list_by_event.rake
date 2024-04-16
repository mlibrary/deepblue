# frozen_string_literal: true

require_relative './noid_list_by_event_task'

namespace :aptrust do

  # bundle exec rake aptrust:noid_list_by_event
  # bundle exec rake aptrust:noid_list_by_event['{"event":"upload_again"}']
  # bundle exec rake aptrust:noid_list_by_event['{"event":"upload_skipped"}']
  # bundle exec rake aptrust:noid_list_by_event['{"event":"deposited"}']
  # bundle exec rake aptrust:noid_list_by_event['{"event":"deposited"\,"ruby_list":true}']
  # bundle exec rake aptrust:noid_list_by_event['{"event":"upload_skipped"\,"ruby_list":true}']
  # bundle exec rake aptrust:noid_list_by_event['{"event":"deposited"\,"max_size":'1_000'}']
  # bundle exec rake aptrust:noid_list_by_event['{"event":"deposited"\,"max_size":'1_000_000_000'}']
  # bundle exec rake aptrust:noid_list_by_event['{"event":"deposit_failed"}']
  # bundle exec rake aptrust:noid_list_by_event['{"verbose":true\,"quiet":false}']
  # bundle exec rake aptrust:noid_list_by_event['{"quiet":true}']
  desc 'List NOIDS by APTrust Status Event'
  task :noid_list_by_event, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = ::Aptrust::NoidListByEventTask.new( options: args[:options] )
    task.run
  end

end
