# frozen_string_literal: true

namespace :deepblue do

  # bundle exec rake deepblue:run_job['{"job_class":"HeartBeat"\,"verbose":true}']
  desc 'Run a job'
  task :run_job, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    options = args[:options]
    task = Deepblue::RunJobTask.new( options: options )
    task.run
  end

end

module Deepblue

  class RunJobTask < AbstractTask

    def initialize( options: {} )
      super( options: options )
    end

    def run
      @verbose = TaskHelper.task_options_value( @options, key: 'verbose', default_value: DEFAULT_VERBOSE )
      @job_class = TaskHelper.task_options_value( @options, key: 'job_class', default_value: "" )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "@options=#{@options}",
                                             "@job_class=#{@job_class}",
                                             "@verbose=#{@verbose}",
                                             "" ] if true
      return if @job_class.blank?
      job_class = Object.const_get( @job_class )
      job = job_class.new( *@options )
      job.perform_now
    rescue NameError => e
      Rails.logger.error "#{e.class} #{e.message} at #{e.backtrace[0]}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    rescue Exception => e
      Rails.logger.error "#{e.class} #{e.message} at #{e.backtrace[0]}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end

  end

end
