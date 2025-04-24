# frozen_string_literal: true

require_relative './work_ticket_add_comment_task'

namespace :deepblue do

  # see: app/services/deepblue/teamdynamix_service.rb for status_id values

  # bundle exec rake deepblue:work_ticket_add_comment['f4752g72m','comment string']
  # bundle exec rake deepblue:work_ticket_add_comment['f4752g72m','comment string','{"verbose":true\,"new_status_id":0\,"notify":"fritx@umich.edu"}']
  desc 'Add ticket comment to the given work.'
  task :work_ticket_add_comment, %i[ id comment options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = ::Deepblue::WorkTicketAddCommentTask.new( id: args[:id], comment: args[:comment], options: args[:options] )
    task.run
  end

end
