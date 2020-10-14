# frozen_string_literal: true

class AbstractIngestJob < ::Hyrax::ApplicationJob

  ABSTRACT_INGEST_JOB_DEBUG_VERBOSE = false

  attr_accessor :job_status

  def find_or_create_job_status_started( parent_job_id: nil, continue_job_chain_later: false )
    @job_status = IngestJobStatus.find_or_create_job_started( job: self,
                                                              parent_job_id: parent_job_id,
                                                              continue_job_chain_later: continue_job_chain_later )
  end

  def job_status
    @job_status ||= job_status_init
  end

  def job_status_init
    IngestJobStatus.find_or_create_job_started( job: self )
  end

  def log_error( msg )
    Rails.logger.error msg
    job_status.add_error! msg if job_status.present?
  end

end
