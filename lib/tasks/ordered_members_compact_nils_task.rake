# frozen_string_literal: true

namespace :deepblue do

  # bundle exec rake deepblue:ordered_members_compact_nils
  # bundle exec rake deepblue:ordered_members_compact_nils['{"verbose":true}']
  desc 'Ordered members compact nils.'
  task :ordered_members_compact_nils, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    options = args[:options]
    task = Deepblue::OrderedMembersCompactNilsTask.new( options: options )
    task.run
  end

end

module Deepblue

  require 'tasks/abstract_task'

  class OrderedMembersCompactNilsTask < AbstractTask

    def initialize( options: {} )
      super( options: options )
    end

    def run
      ActiveFedora::Base.all.each do |cc|
        next unless cc.respond_to? :ordered_members
        ord = Array( cc.ordered_members )
        puts "#{cc.id} ord.size=#{ord.size}" if verbose
        puts "#{cc.id} ord.count(nil)=#{ord.count(nil)}" if verbose
        next unless 0 < ord.count(nil)
        ord = ord.compact
        puts "#{cc.id} ord.size=#{ord.size}" if verbose
        w.ordered_members = ord
        w.save
        puts if verbose
      end
    end

  end

end
