# frozen_string_literal: true

require_relative '../../app/tasks/deepblue/report_task'
require 'tasks/ensure_doi_minted_task'

namespace :deepblue do

  # bundle exec rake deepblue:ensure_doi_minted['f4752g72m']
  # bundle exec rake deepblue:ensure_doi_minted['f4752g72m','{"verbose":true}']
  desc 'Ensure DOI minted for a given work.'
  task :ensure_doi_minted, %i[ id options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = ::Deepblue::EnsureDoiMintedTask.new( id: args[:id], options: args[:options] )
    task.run
  end

end
