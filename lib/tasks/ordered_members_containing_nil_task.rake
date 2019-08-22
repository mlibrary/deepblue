# frozen_string_literal: true

namespace :deepblue do

  # bundle exec rake deepblue:ordered_members_containing_nil['{"mode":"report"}']
  desc 'Ordered members containing nil.'
  task :ordered_members_containing_nil, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    options = args[:options]
    task = Deepblue::OrderedMembersContainingNilTask.new( options: options )
    task.run
  end

end

module Deepblue

  require 'tasks/abstract_task'

  class OrderedMembersContainingNilTask < AbstractTask

    def initialize( options: {} )
      super( options: options )
    end

    def run
      @mode = task_options_value( key: 'mode', default_value: 'report' )
      ids = []
      works = DataSet.all
      puts "#{works.size} works"
      works.each_with_index do |w,i|
        print '.'
        STDOUT.flush
        puts " #{ids}" if 0 == i % 50
        begin
          ord = Array( w.ordered_members )
          ids << w.id if ord.count(nil) > 0
        rescue
          ids << w.id
        end
      end
      puts "#{ids.size} - #{ids}"
    end

  end

end
