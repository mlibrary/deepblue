# frozen_string_literal: true

require 'tasks/clean_ahoy_visits_task'

namespace :deepblue do

  # bundle exec rake deepblue:clean_ahoy_visits
  # bundle exec rake deepblue:clean_ahoy_visits['{"verbose":true}']
  desc 'Clean Ahoy Visits'
  task :clean_ahoy_visits, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = Deepblue::CleanAhoyVisitsTask.new( options: args[:options] )
    task.run
  end

end
