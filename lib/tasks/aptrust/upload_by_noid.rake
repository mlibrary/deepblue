# frozen_string_literal: true

require_relative './upload_by_noid_task'

namespace :aptrust do

  # bundle exec rake aptrust:upload_by_noid
  # bundle exec rake aptrust:upload_by_noid['{"noids":"noid1"}']
  # bundle exec rake aptrust:upload_by_noid['{"noids":"noid1"\,"sleep_secs":30\,"debug_verbose":true}']
  # bundle exec rake aptrust:upload_by_noid['{"noids":"noid1"\,"debug_assume_upload_succeeds":true}']
  # bundle exec rake aptrust:upload_by_noid['{"noids":"noid1 noid2"}']
  # bundle exec rake aptrust:upload_by_noid['{"noids":"noid1"\,"verbose":true\,"quiet":false}']
  # bundle exec rake aptrust:upload_by_noid['{"noids":"noid1"\,"verbose":true\,"debug_verbose":true}']
  # bundle exec rake aptrust:upload_by_noid['{"noids":"noid1"\,"quiet":true}']
  desc 'Upload to APTrust by list of noids'
  task :upload_by_noid, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = ::Aptrust::UploadByNoidTask.new( options: args[:options] )
    task.run
  end

end
