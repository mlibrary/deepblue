# frozen_string_literal: true

require_relative "./deepblue/deepblue_job"

class TestJob < ::Deepblue::DeepblueJob

  mattr_accessor :test_job_debug_verbose
  @@test_job_debug_verbose = false

  def perform( *args )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "args=#{args}",
                                           # "arguments=#{arguments}",
                                           # "executions=#{executions}",
                                           # "job_id=#{job_id}",
                                           # "locale=#{locale}",
                                           # "priority=#{priority}",
                                           # "provider_job_id=#{provider_job_id}",
                                           # "queue_name=#{queue_name}",
                                           # "scheduled_at=#{scheduled_at}",
                                           "" ] if test_job_debug_verbose
    job_status_init
    # and some stuff would happen here
    job_status.finished!
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: args )
    raise e
  end

end
