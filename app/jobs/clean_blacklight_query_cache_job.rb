# frozen_string_literal: true

require_relative "../tasks/deepblue/yaml_populate_for_collection"

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

  EVENT = "clean blacklight query cache"

  def perform( *args )
    initialize_options_from( *args, debug_verbose: clean_blacklight_query_cache_job_debug_verbose )
    increment_day_span = job_options_value( key: 'increment_day_span', default_value: 15 )
    max_day_spans = job_options_value( key: 'max_day_spans', default_value: 0 )
    start_day_span = job_options_value( key: 'start_day_span', default_value: 30 )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "increment_day_span=#{increment_day_span}",
                                           "max_day_spans=#{max_day_spans}",
                                           "start_day_span=#{start_day_span}",
                                           "" ] if debug_verbose
    log( event: EVENT, hostname_allowed: hostname_allowed? )
    return job_finished unless hostname_allowed?
    ::Deepblue::CleanUpHelper.clean_blacklight_query_cache( increment_day_span: increment_day_span,
                                                            start_day_span: start_day_span,
                                                            max_day_spans: max_day_spans,
                                                            msg_handler: msg_handler,
                                                            task: task,
                                                            verbose: verbose,
                                                            debug_verbose: debug_verbose )
    email_all_targets( task_name: EVENT, event: EVENT )
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: args )
    email_failure( task_name: EVENT, exception: e, event: EVENT )
    raise e
  end

end
