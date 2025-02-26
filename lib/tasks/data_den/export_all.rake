# frozen_string_literal: true

require_relative './export_all_task'

namespace :data_den do

  # bundle exec rake data_den:export_all
  desc 'DataDen export all (max data set size based on configuration) all (both new and modified).'
  task :export_all, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = ::DataDen::ExportAllTask.new( options: args[:options] )
    task.run
  end

end
