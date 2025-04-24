# frozen_string_literal: true

class SleepJob < ::Deepblue::DeepblueJob

  mattr_accessor :sleep_job_debug_verbose, default: false
  @@bold_puts = false

  #def perform( job_delay_in_seconds: )
  def perform( *args )
    args = [{}] if args.nil? || args[0].nil?
    job_delay_in_seconds = args[0][:job_delay_in_seconds]
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
