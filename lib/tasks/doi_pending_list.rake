# frozen_string_literal: true

require_relative './doi_pending_list_task'

namespace :deepblue do

  # bundle exec rake deepblue:doi_pending_list
  # bundle exec rake deepblue:doi_pending_list['{"ruby_list":true}']
  # bundle exec rake deepblue:doi_pending_list['{"verbose":true\,"quiet":false}']
  # bundle exec rake deepblue:doi_pending_list['{"quiet":true}']
  desc 'List pending DOI DataSet IDs'
  task :doi_pending_list, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = ::Deepblue::DoiPendingListTask.new( options: args[:options] )
    task.run
  end

end
