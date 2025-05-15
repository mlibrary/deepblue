# frozen_string_literal: true

require_relative '../../app/tasks/deepblue/abstract_task'
require_relative '../../app/services/ahoy/visits_cleaner'

module Deepblue

SCHEDULER_ENTRY = <<-END_OF_SCHEDULER_ENTRY

clean_ahoy_visits:
  # Note: all parameters are set in the rake task job
  # Run once a week on Saturday, 6 minutes after midnight (which is offset by 4 or [5 during daylight savings time], due to GMT)
  #       M H D
  cron: '6 4 * * 6'
  class: RakeTaskJob
  queue: scheduler
  description: Run rake task deepblue:clean_ahoy_visits
  args:
    by_request_only: false
    hostnames:
       - 'deepblue.lib.umich.edu'
    job_delay: 0
    subscription_service_id: clean_ahoy_visits
    rake_task: "deepblue:clean_ahoy_visits"

END_OF_SCHEDULER_ENTRY

  class CleanAhoyVisitsTask < AbstractTask

    attr_accessor :begin_date
    attr_accessor :trim_date
    attr_accessor :inc
    attr_accessor :opt_debug_verbose

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
      # see: Aptrust::UploadLimitedAllTask for version that sets msg_handler and other tracking vars
      if msg_handler.nil?
        @verbose = true
        @msg_handler.verbose = @verbose
        @msg_handler.msg_queue = []
      else
        @verbose = @msg_handler.verbose
      end
      @begin_date = task_options_value( key: 'begin_date', default_value: DateTime.now - 40.days ) # i.e. 'now - 40 days'
      @begin_date = to_datetime( date: @begin_date ) if @begin_date.is_a?( String )
      @trim_date = task_options_value( key: 'trim_date', default_value: DateTime.now - 4.days ) # i.e. 'now - 4 days'
      @trim_date = to_datetime( date: @trim_date ) if @trim_date.is_a?( String )
      @inc = task_options_value( key: 'trim_date', default_value: 4.days ) # i.e. 'now - 4 days'
      @inc = to_datetime( date: @inc ) if @inc.is_a?( String )
    end

    def run
      # cleaner = Ahoy::VisitsCleaner.new( begin_date: DateTime.now - 480.days, trim_date: DateTime.now - 7.days, inc: 7.days, delete: true, verbose: true, debug_verbose: false, msg_handler: ::Deepblue::MessageHandler.msg_handler_for( task: true ) )
      # cleaner.run
      # cleaner = Ahoy::VisitsCleaner.new( begin_date: DateTime.now - 180.days, trim_date: DateTime.now - 7.days, inc: 7.days, delete: true, verbose: true, debug_verbose: false, msg_handler: ::Deepblue::MessageHandler.msg_handler_for( task: true ) )
      # cleaner.run
      # cleaner = Ahoy::VisitsCleaner.new( begin_date: DateTime.now - 180.days, trim_date: DateTime.now - 5.days, inc: 5.days, delete: true, verbose: true, debug_verbose: false, msg_handler: ::Deepblue::MessageHandler.msg_handler_for( task: true ) )
      # cleaner.run
      # cleaner = Ahoy::VisitsCleaner.new( begin_date: DateTime.now - 180.days, trim_date: DateTime.now - 4.days, inc: 4.days, delete: true, verbose: true, debug_verbose: false, msg_handler: ::Deepblue::MessageHandler.msg_handler_for( task: true ) )
      # cleaner.run
      cleaner = Ahoy::VisitsCleaner.new( begin_date: @begin_date,
                                         trim_date: @trim_date,
                                         inc: @inc,
                                         delete: true,
                                         verbose: true,
                                         debug_verbose: false,
                                         msg_handler: ::Deepblue::MessageHandler.msg_handler_for( task: true ) )
      cleaner.run
    end

  end

end
