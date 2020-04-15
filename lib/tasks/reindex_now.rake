# frozen_string_literal: true

require_relative './resolrize_job2'

namespace :solr do

  desc "Reindex solr cores with perform_now."
  task reindex!: :environment do |_t|
    puts "Performing Resolrize now."
    ::Deepblue::ResolrizeJob2.perform_now
  end

end

namespace :deepblue do

  # bundle exec rake deepblue:reindex_solr_now
  desc "Reindex solr from fedora with ResolrizeJob.perform_now."
  task reindex_solr_now: :environment do |_t|
    puts "Performing Resolrize now."
    ::Deepblue::ResolrizeJob2.perform_now
  end

end
