# frozen_string_literal: true

require_relative './fedora_accessible'

namespace :deepblue do

  # bundle exec rake deepblue:fedora_accessible['{"verbose":true}']
  desc 'Fedora accessible check.'
  task :fedora_accessible, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    options = args[:options]
    task = ::Deepblue::FedoraAccessible.new( options: options )
    task.run
  end

end
