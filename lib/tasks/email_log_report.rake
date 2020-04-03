# frozen_string_literal: true

namespace :deepblue do

  # bundle exec rake deepblue:email_log_report
  # bundle exec rake deepblue:email_log_report['{"verbose":true}']
  # bundle exec rake deepblue:email_log_report['{"input":"./log/email_development.log"}']
  # bundle exec rake deepblue:email_log_report['{"input":"./log/email_production.log"}']
  # bundle exec rake deepblue:email_log_report['{"input":"./log/email_testing.log"}']
  # bundle exec rake deepblue:email_log_report['{"input":"./log/email_development.log"\,"begin":"2020-04-01 00:00:00"\,"end":""\,"format":"%Y-%m-%d %H:%M:%S"}']
  desc 'Report on emails'
  task :email_log_report, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    task = Deepblue::EmailLogReport.new( options: args[:options] )
    task.run
  end

end

module Deepblue

  require 'tasks/abstract_log_task'
  require_relative '../../app/services/deepblue/email_log_reporter'

  class EmailLogReport < AbstractLogTask

    def initialize( options: )
      super( options: options, pass_all_options: true )
      @reporter = EmailLogReporter.new( input: @input, options: options_to_pass.merge( @options ) )
    end

    def initialize_input
      task_options_value( key: 'input', default_value: nil )
    end

    def run
      @reporter.report
    end

  end

end
