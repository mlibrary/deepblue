# frozen_string_literal: true

namespace :deepblue do

  # There are a lot of possible parameters to this task, see lib/tasks/export_import_cmd_generator.rb
  # bundle exec rake deepblue:export_cmds['{"mode":"build"\,"input_csv_file":"/deepbluedata-prep/reports/20181015_works_report_works_sorted.csv"\,"target_dir":"/deepbluedata-tmp/DBDv1/"}']
  desc 'Generate export commands'
  task :export_cmds, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = Deepblue::GenerateExportCmds.new( options: args[:options] )
    task.run
    puts "Script written to: #{task.script_name}"
  end

  # There are a lot of possible parameters to this task, see lib/tasks/export_import_cmd_generator.rb
  # bundle exec rake deepblue:import_cmds['{"verbose":"true"\,"shell_task":"build"\,"import_options":"-w -verbose -d"\,"input_csv_file":"/deepbluedata-prep/reports/20181015_works_report_works_sorted.csv"\,"target_dir":"/deepbluedata-tmp/DBDv1/"}']
  desc 'Generate import commands'
  task :import_cmds, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = Deepblue::GenerateImportCmds.new( options: args[:options] )
    task.run
    puts "Script written to: #{task.script_name}"
  end

end

module Deepblue

  require_relative 'export_import_cmd_generator'

  class GenerateExportCmds < ExportImportCmdGenerator

    def initialize( options: )
      super( cmd_mode: 'export', options: options )
    end

    def run
      print_all_scripts
    end

  end

  class GenerateImportCmds < ExportImportCmdGenerator

    def initialize( options: )
      super( cmd_mode: 'import', options: options )
    end

    def run
      print_all_scripts
    end

  end

end
