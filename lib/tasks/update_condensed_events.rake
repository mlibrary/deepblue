# frozen_string_literal: true

require_relative './update_condensed_events_task'

namespace :deepblue do

  # bundle exec rake deepblue:update_condensed_events
  # bundle exec rake deepblue:update_condensed_events['{"verbose":true}']
  # bundle exec rake deepblue:update_condensed_events['{"verbose":true\,"begin_date":"now-1 month"\,"end_date":"now"}']
  desc 'Report on fixity of ingested files'
  task :update_condensed_events, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = Deepblue::UpdateCondensedEventsTask.new( options: args[:options] )
    task.run
  end

end
