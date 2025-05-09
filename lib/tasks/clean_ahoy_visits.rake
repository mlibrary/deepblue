# frozen_string_literal: true

require 'tasks/clean_ahoy_visits_task'

namespace :deepblue do

  # bundle exec rake deepblue:clean_ahoy_visits
  # bundle exec rake deepblue:clean_ahoy_visits['{"verbose":true}']
  # default: bundle exec rake deepblue:clean_ahoy_visits['{"begin_date":"now - 40 days"\,"trim_date":"now - 4 days"\,"inc":"4 days"}']
  # default: bundle exec rake deepblue:clean_ahoy_visits['{"begin_date":"now - 40 days"\,"trim_date":"now - 2 days"\,"inc":"4 days"}']
  desc 'Clean Ahoy Visits'
  task :clean_ahoy_visits, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = Deepblue::CleanAhoyVisitsTask.new( options: args[:options] )
    task.run
  end

end
