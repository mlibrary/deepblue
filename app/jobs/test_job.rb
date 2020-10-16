# frozen_string_literal: true

class TestJob < ::Hyrax::ApplicationJob

  TEST_JOB_DEBUG_VERBOSE = true

  def perform( *args )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "self.class.name=#{self.class.name}",
                                           "args=#{args}",
                                           "arguments=#{arguments}",
                                           "executions=#{executions}",
                                           "job_id=#{job_id}",
                                           "locale=#{locale}",
                                           "priority=#{priority}",
                                           "provider_job_id=#{provider_job_id}",
                                           "queue_name=#{queue_name}",
                                           "scheduled_at=#{scheduled_at}",
                                           "" ] if TEST_JOB_DEBUG_VERBOSE
    job_status = JobStatus.find_or_create_job_started( job: self )
    # and some stuff would happen here
    job_status.finished!
  rescue Exception => e # rubocop:disable Lint/RescueException
    msg = "TestJob.perform(#{args}) #{e.class}: #{e.message}"
    Rails.logger.error msg
    JobStatus.find_or_create_job_error( job: self, error: msg )
    raise e
  end

end
