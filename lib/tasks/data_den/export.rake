# frozen_string_literal: true

require_relative './export_task'

namespace :data_den do

  # bundle exec rake data_den:export
  # bundle exec rake data_den:export['{"verbose":true\,"test_mode":true}']
  # bundle exec rake data_den:export['{"verbose":true\,"test_mode":true\,"max_size":"1_000_000"}']
  # bundle exec rake data_den:export['{"verbose":true\,"test_mode":true\,"max_exports":1}']
  # bundle exec rake data_den:export['{"verbose":true\,"test_mode":true\,"date_end":"2024/03/22 00:00:00"}']
  # bundle exec rake data_den:export['{"verbose":true\,"test_mode":true\,"date_begin":"2024/03/22 00:00:00"}']
  # bundle exec rake data_den:export['{"date_end":"2024/03/22 00:00:00"}']
  # bundle exec rake data_den:export['{"date_begin":"2024/03/01 00:00:00"\,"date_end":"2024/03/22 00:00:00"}']
  # bundle exec rake data_den:export['{"date_end":"2024/03/22 00:00:00"\,"max_size":"1_000_000"\,"event":"failed"\,"verbose":true}']
  # bundle exec rake data_den:export['{"verbose":true\,"quiet":false}']
  # bundle exec rake data_den:export['{"verbose":true\,"debug_verbose":true}']
  # bundle exec rake data_den:export['{"email_targets":"fritx@umich.edu"}']
  # bundle exec rake data_den:export['{"email_targets":"fritx@umich.edu"\,"email_subject":"%hostname%-%subject% finished at %timestamp%"}']
  desc 'Export to DataDen by list of noids'
  task :export, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = ::DataDen::ExportTask.new( options: args[:options] )
    task.run
  end

end
