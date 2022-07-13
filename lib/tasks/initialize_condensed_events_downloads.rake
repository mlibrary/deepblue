# frozen_string_literal: true

require_relative './initialize_condensed_events_downloads_task'

namespace :deepblue do

  # bundle exec rake deepblue:initialize_condensed_events_downloads
  # bundle exec rake deepblue:initialize_condensed_events_downloads['{"verbose":true}']
  # bundle exec rake deepblue:initialize_condensed_events_downloads['{"verbose":true\,"force":true}']
  # bundle exec rake deepblue:initialize_condensed_events_downloads['{"verbose":true\,"only_published":true}']
  # bundle exec rake deepblue:initialize_condensed_events_downloads['{"verbose":true\,"clean_work_events":true}']
  # bundle exec rake deepblue:initialize_condensed_events_downloads['{"verbose":false\,"task_id":"init_ce_downloads"}']

  desc 'Initialize condensed events downloads'
  task :initialize_condensed_events_downloads, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    options = ::Deepblue::OptionsHelper.parse args[:options]
    msg_handler = ::Deepblue::MessageHandler.msg_handler_for_task( options: options )
    task = ::Deepblue::InitializeCondensedEventsDownloadsTask.new( msg_handler: msg_handler, options: options )
    task.run
  end

end
