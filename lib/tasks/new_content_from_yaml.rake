# frozen_string_literal: true

require_relative './new_content_from_yaml'

namespace :deepblue do

  # bundle exec rake deepblue:new_content_from_yaml['f4752g72m g4752g72m','{"source_dir":"/deepbluedata-dataden/download-prep"\,"mode":"build"\,"prefix":""\,"postfix":"_populate"\,"ingester":"ingester@umich.edu"}']
  desc 'New content from yaml files (base file names separated by spaces)'
  task :new_content_from_yaml, %i[ base_file_names options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = Deepblue::NewContentFromYaml.new( base_file_names: args[:base_file_names],
                                             options: args[:options] )
    task.run
  end

end
