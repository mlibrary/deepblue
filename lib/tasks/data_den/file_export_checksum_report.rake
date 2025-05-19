# frozen_string_literal: true

require_relative './file_export_checksum_report_task'

namespace :data_den do

  # bundle exec rake data_den:file_export_checksum_report_task
  desc 'Report DataDen file export checksums.'
  task :file_export_checksum_report_task, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = ::DataDen::FileExportChecksumReportTask.new( options: args[:options] )
    task.run
  end

end
