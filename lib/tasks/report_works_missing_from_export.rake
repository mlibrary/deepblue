# frozen_string_literal: true

namespace :deepblue do

  # bundle exec rake deepblue:report_works_missing_from_export['{"export_dir":"/deepbluedata-tmp/2018_DBDv1"\,"input_csv_file":"/deepbluedata-tmp/2018_DBDv1_baseline/20181019_works_report_works.csv"}']
  desc 'Report all exported works listed in specified csv file in export directory.'
  task :report_works_missing_from_export, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    options = args[:options]
    task = Deepblue::ReportWorksMissingFromExport.new( options: options )
    task.run
  end

end

module Deepblue

  require 'csv'
  require 'tasks/abstract_task'

  class ReportWorksMissingFromExport < AbstractTask

    DEFAULT_EXPORT_DIR = Pathname.new "/deepbluedata-tmp/2018_DBDv1" unless const_defined? :DEFAULT_EXPORT_DIR
    DEFAULT_INPUT_CSV_FILE = "/deepbluedata-tmp/2018_DBDv1_baseline/20181019_works_report_works.csv" unless const_defined? :DEFAULT_INPUT_CSV_FILE

    attr_reader :ids_missing_yml_files, :ids_missing_pop_dirs, :input_csv_file, :export_dir

    def initialize( options: {} )
      super( options: options )
      @export_dir = TaskHelper.task_options_value( @options, key: 'export_dir', default_value: DEFAULT_EXPORT_DIR )
      @input_csv_file = TaskHelper.task_options_value( @options, key: 'input_csv_file', default_value: DEFAULT_INPUT_CSV_FILE )
    end

    def run
      @ids_missing_yml_files = []
      @ids_missing_pop_dirs = []
      CSV.foreach( @input_csv_file ) do |row|
        id = row[0]
        next if 'Id' == id
        pop_file = @export_dir.join "w_#{id}_populate.yml"
        pop_dir = @export_dir.join "w_#{id}_populate"
        unless pop_file.exist?
          @ids_missing_yml_files << id
          puts "#{id}: file not found #{pop_file}"
        end
        unless pop_dir.directory?
          @ids_missing_pop_dirs << id
          puts "#{id}: directory not found #{pop_dir}"
        end
      end
    end

  end

end
