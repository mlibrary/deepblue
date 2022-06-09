# frozen_string_literal: true

require_relative "../../lib/tasks/yaml_populate_for_collection"

class CleanBlacklightQueryCacheJob < ::Deepblue::DeepblueJob

  mattr_accessor :clean_blacklight_query_cache_job_debug_verbose,
                 default: ::Deepblue::JobTaskHelper.clean_blacklight_query_cache_job_debug_verbose

  SCHEDULER_ENTRY = <<-END_OF_SCHEDULER_ENTRY

clean_blacklight_query_cache:
  # Run once a week at midnight
  #      M H D
  # cron: '*/5 * * * *'
  cron: '0 5 * * 0'
  class: ExportLogFilesJob
  queue: default
  description: Delete cached blacklight queries older than 30 days job.
  args:
    by_request_only: true
    hostnames:
      - 'deepblue.lib.umich.edu'
      - 'staging.deepblue.lib.umich.edu'
      - 'testing.deepblue.lib.umich.edu'
    start_day_spans: 30
    increment_day_span: 15
    max_day_spans: 1
    verbose: true

END_OF_SCHEDULER_ENTRY

  queue_as :default

  def perform( *args )
    debug_verbose = clean_blacklight_query_cache_job_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "args=#{args}",
                                           "" ] if debug_verbose
    initialize_options_from( *args, debug_verbose: debug_verbose )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "options=#{options}",
                                           "" ] if debug_verbose
    increment_day_span = job_options_value( options, key: 'increment_day_span', default_value: 15, verbose: verbose )
    max_day_spans = job_options_value( options, key: 'max_day_spans', default_value: 0, verbose: verbose )
    start_day_span = job_options_value( options, key: 'start_day_span', default_value: 30, verbose: verbose )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "increment_day_span=#{increment_day_span}",
                                           "max_day_spans=#{max_day_spans}",
                                           "start_day_span=#{start_day_span}",
                                           "" ] if debug_verbose
    event = "clean blacklight query cache"
    log( event: event, hostname_allowed: hostname_allowed? )
    return job_finished unless hostname_allowed?
    msg_handler = ::Deepblue::MessageHandler.new( msg_queue: job_msg_queue, task: task, verbose: verbose )
    ::Deepblue::CleanUpHelper.clean_blacklight_query_cache( increment_day_span: increment_day_span,
                                                            start_day_span: start_day_span,
                                                            max_day_spans: max_day_spans,
                                                            msg_handler: msg_handler,
                                                            task: task,
                                                            verbose: verbose,
                                                            debug_verbose: clean_blacklight_query_cache_job_debug_verbose )
    email_all_targets( task_name: event,
                       event: event ,
                       body: msg_handler.join("\n"),
                       debug_verbose: clean_blacklight_query_cache_job_debug_verbose )
    job_finished

  rescue Exception => e # rubocop:disable Lint/RescueException
    email_all_targets( task_name: event,
                       event: event ,
                       body: job_msg_queue.join("\n") + e.message + "\n" + e.backtrace.join("\n"),
                       debug_verbose: clean_blacklight_query_cache_job_debug_verbose )
    job_status_register( exception: e, args: args )
    raise e

  end

end
