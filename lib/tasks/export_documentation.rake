# frozen_string_literal: true

require_relative '../../app/services/deepblue/work_view_content_service'

namespace :deepblue do

  # bundle exec rake deepblue:export_documentation
  # bundle exec rake deepblue:export_documentation['{"target_dir":"./tmp"}']
  desc 'Export documenation to set of yaml files'
  task :export_documentation, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    id = ::Deepblue::WorkViewContentService.content_documentation_collection_id
    task = Deepblue::YamlPopulateFromCollection.new( id: id, options: args[:options] )
    task.run
  end

end
