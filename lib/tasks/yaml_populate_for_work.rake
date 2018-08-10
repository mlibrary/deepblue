# frozen_string_literal: true

require 'open-uri'

namespace :deepblue do

  # bundle exec rake umrdr:yaml_populate_from_work[f4752g72m,/deepbluedata-prep,true]
  desc 'Yaml populate from work'
  # See: https://stackoverflow.com/questions/825748/how-to-pass-command-line-arguments-to-a-rake-task
  task :yaml_populate_from_work, %i[ work_id target_dir export_files ] => :environment do |_task, args|
    # puts "upgrade_provenance_log", args.as_json
    args.with_defaults( target_dir: '/deepbluedata-prep', export_files: 'true' )
    task = Deepblue::YamlPopulateFromWork.new( work_id: args[:work_id],
                                               target_dir: args[:target_dir],
                                               export_files: args[:export_files] )
    task.run
  end

  # bundle exec rake umrdr:yaml_populate_from_multiple_works['f4752g72m f4752g72m',/deepbluedata-prep,true]
  desc 'Yaml populate from multiple works (ids separated by spaces)'
  task :yaml_populate_from_multiple_works, %i[ work_ids target_dir export_files ] => :environment do |_task, args|
    # puts "upgrade_provenance_log", args.as_json
    args.with_defaults( target_dir: '/deepbluedata-prep', export_files: 'true' )
    task = Deepblue::YamlPopulateFromMultipleWorks.new( work_ids: args[:work_ids],
                                                        target_dir: args[:target_dir],
                                                        export_files: args[:export_files] )
    task.run
  end

end

module Deepblue

  # see: http://ruby-doc.org/stdlib-2.0.0/libdoc/benchmark/rdoc/Benchmark.html
  require 'benchmark'
  include Benchmark

  class YamlPopulate

    def report( first_id:, measurements:, total: nil )
      label = 'work id'
      label += ' ' * (first_id.size - label.size)
      puts "#{label} #{Benchmark::CAPTION}"
      format = Benchmark::FORMAT.chop
      measurements.each do |measurement|
        label = measurement.label
        puts measurement.format( "#{label} #{format} is #{seconds_to_readable(measurement.real)}\n" )
      end
      return if total.blank?
      label = 'total'
      label += ' ' * (first_id.size - label.size)
      puts total.format( "#{label} #{format} is #{seconds_to_readable(total.real)}\n" )
    end

    def seconds_to_readable( seconds )
      h, min, s, _fr = split_seconds( seconds )
      return "#{h} hours, #{min} minutes, and #{s} seconds"
    end

    def split_seconds( fr )
      # ss,  fr = fr.divmod(86_400) # 4p
      ss = ( fr + 0.5 ).to_int
      h,   ss = ss.divmod(3600)
      min, s  = ss.divmod(60)
      return h, min, s, fr
    end

  end

  class YamlPopulateFromWork < Deepblue::YamlPopulate

    def initialize( work_id:, target_dir:, export_files: )
      @work_id = work_id
      @target_dir = target_dir
      @export_files = export_files.casecmp( 'true' ).zero?
    end

    def run
      measurement = Benchmark.measure( @work_id ) do
        puts "Exporting work #{@work_id} to '#{@target_dir}' with export files flag set to #{@export_files}"
        Deepblue::MetadataHelper.yaml_populate_work( curation_concern: @work_id,
                                                     dir: @target_dir,
                                                     export_files: @export_files )
      end
      report( first_id: @work_id, measurements: [measurement] )
    end

  end

  class YamlPopulateFromMultipleWorks < Deepblue::YamlPopulate

    def initialize( work_ids:, target_dir:, export_files: )
      @work_ids = work_ids
      @target_dir = target_dir
      @export_files = export_files.casecmp( 'true' ).zero?
    end

    def run
      ids = @work_ids.split( ' ' )
      return if ids.blank?
      first_id = ids[0]
      total = nil
      measurements = []
      ids.each do |id|
        subtotal = Benchmark.measure( id ) do
          puts "Exporting work #{id} to '#{@target_dir}' with export files flag set to #{@export_files}"
          Deepblue::MetadataHelper.yaml_populate_work( curation_concern: id,
                                                       dir: @target_dir,
                                                       export_files: @export_files )
        end
        measurements << subtotal
        if total.nil?
          total = subtotal
        else
          total += subtotal
        end
      end
      report( first_id: first_id, measurements: measurements, total: total )
    end

  end

end
