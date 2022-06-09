# frozen_string_literal: true

require 'tasks/report_task'
require 'tasks/ensure_doi_minted_task'

namespace :deepblue do

  # bundle exec rake deepblue:work_find_and_fix['f4752g72m']
  # bundle exec rake deepblue:work_find_and_fix['f4752g72m','{"verbose":true}']
  desc 'Run find and fix algorithm for given work.'
  task :work_find_and_fix, %i[ id options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = ::Deepblue::WorkFindAndFixTask.new( id: args[:id], options: args[:options] )
    task.run
  end

end
