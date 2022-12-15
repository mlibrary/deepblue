# frozen_string_literal: true

# bundle exec rake deepblue:run_job['{"job_class":"HeartBeat"\,"verbose":true}']
class IngestAppendScriptMonitorJob < ::Deepblue::DeepblueJob

  mattr_accessor :ingest_append_script_monitor_job_debug_verbose, default: true
  @@bold_puts = true

  def perform( job_class_name:, job_args:, wait_duration: 1 )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "job_class_name=#{job_class_name}",
                                           "job_args=#{job_args}",
                                           "wait_duration=#{wait_duration}",
                                           "" ], bold_puts: @@bold_puts if ingest_append_script_monitor_job_debug_verbose
    job_class = job_class_name.constantize
    job = job_class.send(:job_or_instantiate, **job_args )
    job_id = job.job_id
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "job=#{job}",
                                           "job_id=#{job_id}",
                                           "" ], bold_puts: @@bold_puts if ingest_append_script_monitor_job_debug_verbose
    if Rails.env.development?
      rv = job.perform_now
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ], bold_puts: @@bold_puts if ingest_append_script_monitor_job_debug_verbose
    else
      rv = job.perform_later
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ], bold_puts: @@bold_puts if ingest_append_script_monitor_job_debug_verbose
      while job_running?( job_id ) do
        sleep wait_duration
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "job finished: job_id=#{job_id}",
                                             "" ], bold_puts: @@bold_puts if ingest_append_script_monitor_job_debug_verbose
    end

  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: args )
    raise e
  end

end
