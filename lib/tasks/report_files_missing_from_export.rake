# frozen_string_literal: true

namespace :deepblue do

  # bundle exec rake deepblue:report_files_missing_from_export['{"export_dir":"/deepbluedata-tmp/2018_DBDv1"\,"input_csv_file":"/deepbluedata-tmp/2018_DBDv1_baseline/20181019_works_report_file_sets.csv"}']
  desc 'Report all exported files listed in specified csv file in export directory.'
  task :report_files_missing_from_export, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    options = args[:options]
    task = Deepblue::ReportFilesMissingFromExport.new( options: options )
    task.run
  end

end

module Deepblue

  require 'csv'
  require 'tasks/abstract_task'

  class ReportFilesMissingFromExport < AbstractTask

    DEFAULT_EXPORT_DIR = Pathname.new "/deepbluedata-tmp/2018_DBDv1" unless const_defined? :DEFAULT_EXPORT_DIR
    DEFAULT_INPUT_CSV_FILE = "/deepbluedata-tmp/2018_DBDv1_baseline/20181019_works_report_file_sets.csv" unless const_defined? :DEFAULT_INPUT_CSV_FILE

    attr_reader :input_csv_file, :export_dir
    attr_reader :work_ids_with_missing_files, :file_ids_missing
    attr_reader :work_ids_with_file_size_differ, :file_ids_size_differ
    attr_reader :work_ids_with_zero_file_sizes, :file_ids_with_zero_sizes

    def initialize( options: {} )
      super( options: options )
      @export_dir = TaskHelper.task_options_value( @options, key: 'export_dir', default_value: DEFAULT_EXPORT_DIR )
      @input_csv_file = TaskHelper.task_options_value( @options, key: 'input_csv_file', default_value: DEFAULT_INPUT_CSV_FILE )
    end

    def run
      @work_ids_with_missing_files = {}
      @work_ids_with_file_size_differ = {}
      @work_ids_with_zero_file_sizes = {}
      @file_ids_missing = []
      @file_ids_size_differ = []
      @file_ids_with_zero_sizes = []
      CSV.foreach( @input_files_csv_file ) do |row|
        id = row[0]
        next if 'Id' == id
        work_id = row[1]
        pop_dir = @export_dir.join "w_#{work_id}_populate"
        if pop_dir.directory?
          file_name_partial = pop_dir.to_s + "/#{id}_*"
          files = Dir[file_name_partial]
          if files.empty?
            @file_ids_missing << id
            @work_ids_with_missing_files[work_id] = true
            row_join = row.join "','"
            puts "#{id}: file not found #{file_name_partial} -- '#{row_join}'"
          else
            expected_file_size = row[5].to_i
            size = File.size( files[0] )
            unless size == expected_file_size
              @file_ids_size_differ << id
              @work_ids_with_file_size_differ[work_id] = true
              row_join = row.join "','"
              puts "#{id}: file size differ #{files[0]} #{size} bytes -- '#{row_join}'"
            end
          end
        else
          @file_ids_missing << id
          puts "#{id}: work directory not found #{pop_dir}"
        end
      end
      puts "work_ids_with_missing_files=#{@work_ids_with_missing_files.keys}"
      puts "file_ids_missing=#{@file_ids_missing}"
      puts "work_ids_with_file_size_differ=#{@work_ids_with_file_size_differ.keys}"
      puts "file_ids_size_differ=#{@file_ids_size_differ}"
    end

  end

end
