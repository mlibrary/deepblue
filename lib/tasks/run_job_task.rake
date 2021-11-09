# frozen_string_literal: true

namespace :deepblue do

  # bundle exec rake deepblue:run_job['{"job_class":"HeartBeat"\,"verbose":true\,"perform_later":true\,"verbose":true}']
  desc 'Run a job'
  task :run_job, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    options = args[:options]
    task = Deepblue::RunJobTask.new( options: options )
    task.run
  end

end

require_relative '../../app/helpers/deepblue/job_task_helper'

module Deepblue

  class RunJobTask < AbstractTask

    mattr_accessor :run_job_task_debug_verbose, default: ::Deepblue::JobTaskHelper.run_job_task_debug_verbose

    DEFAULT_PERFORM_LATER = false

    def initialize( options: {} )
      super( options: options )
    end

    def run
      @options = @options.merge( { task: true } )
      @verbose = TaskHelper.task_options_value( @options, key: 'verbose', default_value: DEFAULT_VERBOSE )
      @job_class = TaskHelper.task_options_value( @options, key: 'job_class', default_value: "" )
      @perform_later = TaskHelper.task_options_value( @options, key: 'perform_later', default_value: DEFAULT_PERFORM_LATER )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "@options=#{@options}",
                                             "@job_class=#{@job_class}",
                                             "@verbose=#{@verbose}",
                                             "@peform_later=#{@perform_later}",
                                             "" ], bold_puts: true if run_job_task_debug_verbose
      return if @job_class.blank?
      job_class = Object.const_get( @job_class )
      job = job_class.new( *@options )
      if @perform_later
        job.perform_later
      else
        job.perform_now
      end
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
