# frozen_string_literal: true

require_relative './reexport_modified_task'

namespace :data_den do

  # bundle exec rake data_den:reexport_modified
  # bundle exec rake data_den:reexport_modified['{"verbose":true\,"test_mode":true}']
  # bundle exec rake data_den:reexport_modified['{"verbose":true\,"test_mode":true\,"max_size":"1_000_000"}']
  # bundle exec rake data_den:reexport_modified['{"verbose":true\,"test_mode":true\,"max_exports":1}']
  desc 'Export DataDen by last modified date'
  task :reexport_modified, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = ::DataDen::ReexportModifiedTask.new( options: args[:options] )
    task.run
  end

end
