# frozen_string_literal: true

# bundle exec rake deepblue:run_job['{"job_class":"HeartBeat"\,"verbose":true}']
class SleepJob < ::Deepblue::DeepblueJob

  mattr_accessor :sleep_job_debug_verbose, default: true
  @@bold_puts = true

  def perform( job_delay_in_seconds: )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "job_delay_in_seconds=#{job_delay_in_seconds}",
                                           "" ], bold_puts: @@bold_puts if sleep_job_debug_verbose
    job_delay_in_seconds ||= 1
    job_delay_in_seconds = 1 if job_delay_in_seconds < 1
    job_start( email_init: false )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "job_id=#{job_id}",
                                           "" ], bold_puts: @@bold_puts if sleep_job_debug_verbose
    delay_job( job_delay_in_seconds )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "Finished.",
                                           "" ], bold_puts: @@bold_puts if sleep_job_debug_verbose
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: { job_delay_in_seconds: job_delay_in_seconds } )
    raise e
  end

end
