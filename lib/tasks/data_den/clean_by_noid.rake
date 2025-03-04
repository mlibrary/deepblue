# frozen_string_literal: true

require_relative './clean_by_noid_task'

namespace :data_den do

  # bundle exec rake data_den:clean_by_noid['{"noids":"noid1"}']
  # bundle exec rake data_den:clean_by_noid['{"noids":"noid1"\,"sleep_secs":30\,"debug_verbose":true}']
  # bundle exec rake data_den:clean_by_noid['{"noids":"noid1 noid2"}']
  # bundle exec rake data_den:clean_by_noid['{"noids":"noid1"\,"verbose":true\,"quiet":false}']
  # bundle exec rake data_den:clean_by_noid['{"noids":"noid1"\,"verbose":true\,"debug_verbose":true}']
  # bundle exec rake data_den:clean_by_noid['{"noids":"noid1"\,"quiet":true}']
  desc 'Clean to DataDen by list of noids'
  task :clean_by_noid, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = ::DataDen::CleanByNoidTask.new( options: args[:options] )
    task.run
  end

end
