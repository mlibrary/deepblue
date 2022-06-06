# frozen_string_literal: true

require 'tasks/report_task'
require 'tasks/clean_blacklight_query_cache_task'

namespace :deepblue do

  # bundle exec rake deepblue:clean_blacklight_query_cache
  # bundle exec rake deepblue:clean_blacklight_query_cache['{"verbose":true}']
  # bundle exec rake deepblue:clean_blacklight_query_cache['{"max_day_spans":1\,"verbose":true}']
  # bundle exec rake deepblue:clean_blacklight_query_cache['{"start_day_span":30\,"increment_day_span":15\,"max_day_spans":10\,"verbose":true}']
  # bundle exec rake deepblue:clean_blacklight_query_cache['{"start_day_span":45\,"increment_day_span":10\,"max_day_spans":5\,"verbose":true}']
  desc 'Run report'
  task :clean_blacklight_query_cache, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    options = args[:options]
    task = ::Deepblue::CleanBlacklightQueryCacheTask.new( options: options )
    task.run
  end

end
