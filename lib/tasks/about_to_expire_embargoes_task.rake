# frozen_string_literal: true

require_relative './about_to_expire_embargoes_task'

namespace :deepblue do

  # bundle exec rake deepblue:about_to_expire_embargoes['{"test_mode":true}']
  # bundle exec rake deepblue:about_to_expire_embargoes['{"test_mode":true\,"verbose":true}']
  # bundle exec rake deepblue:about_to_expire_embargoes['{"skip_file_sets":true\,"email_owner":false\,"test_mode":true}']
  # bundle exec rake deepblue:about_to_expire_embargoes['{"skip_file_sets":true\,"email_owner":false\,"test_mode":true\,"expiration_lead_days":8}']
  desc 'About to expire embargoes.'
  task :about_to_expire_embargoes, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = ::Deepblue::AboutToExpireEmbargoesTask.new( options: args[:options] )
    task.run
  end

end
