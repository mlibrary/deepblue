# frozen_string_literal: true

namespace :deepblue do

  # bundle exec rake deepblue:user_stats_import
  desc 'Write report of all works'
  task :user_stats_import, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    options = args[:options]
    task = Deepblue::UserStatImporter.new( options: options )
    task.run
  end

end

namespace :hyrax do
  namespace :stats do
    desc "Cache work view, file view & file download stats for all users"
    task user_stats: :environment do
      importer = Hyrax::UserStatImporter.new(verbose: true, logging: true)
      importer.import
    end
  end
end
