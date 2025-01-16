# frozen_string_literal: true

require_relative './reexport_task'

namespace :data_den do

  # bundle exec rake data_den:reexport
  # bundle exec rake data_den:reexport['{"verbose":true\,"test_mode":true}']
  # bundle exec rake data_den:reexport['{"verbose":true\,"export_status":"exported"\,"test_mode":true}']
  # bundle exec rake data_den:reexport['{"verbose":true\,"test_mode":true\,"max_size":"1_000_000"}']
  # bundle exec rake data_den:reexport['{"verbose":true\,"test_mode":true\,"max_exports":1}']
  # bundle exec rake data_den:reexport['{"date_end":"2024/03/22 00:00:00"}']
  # bundle exec rake data_den:reexport['{"date_begin":"2024/03/01 00:00:00"\,"date_end":"2024/03/22 00:00:00"}']
  # bundle exec rake data_den:reexport['{"date_end":"2024/03/22 00:00:00"\,"max_size":"1_000_000"\,"event":"failed"\,"verbose":true}']
  # bundle exec rake data_den:reexport['{"verbose":true\,"quiet":false}']
  # bundle exec rake data_den:reexport['{"verbose":true\,"debug_verbose":true}']
  # bundle exec rake data_den:reexport['{"quiet":true}']
  desc 'Export to APTrust by list of noids'
  task :reexport, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = ::DataDen::ReexportTask.new( options: args[:options] )
    task.run
  end

end
