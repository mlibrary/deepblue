# frozen_string_literal: true

class AbstractIngestJob < ::Hyrax::ApplicationJob

  ABSTRACT_INGEST_JOB_DEBUG_VERBOSE = true || ::Deepblue::IngestIntegrationService.abstract_ingest_job_debug_verbose

  attr_accessor :job_status

  def find_or_create_job_status_started( parent_job_id: nil,
                                         continue_job_chain_later: false,
                                         verbose: ABSTRACT_INGEST_JOB_DEBUG_VERBOSE )

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "parent_job_id=#{parent_job_id}",
                                           "continue_job_chain_later=#{continue_job_chain_later}",
                                           "verbose=#{verbose}",
                                           "" ] if ABSTRACT_INGEST_JOB_DEBUG_VERBOSE
    @job_status = IngestJobStatus.find_or_create_job_started( job: self,
                                                              parent_job_id: parent_job_id,
                                                              continue_job_chain_later: continue_job_chain_later,
                                                              verbose: verbose )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "parent_job_id=#{parent_job_id}",
                                           "continue_job_chain_later=#{continue_job_chain_later}",
                                           "verbose=#{verbose}",
                                           "@job_status.job_id=#{@job_status.job_id}",
                                           "@job_status.parent_job_id=#{@job_status.parent_job_id}",
                                           "@job_status.message=#{@job_status.message}",
                                           "@job_status.error=#{@job_status.error}",
                                           "" ] if ABSTRACT_INGEST_JOB_DEBUG_VERBOSE
    @job_status.add_message! "#{self.class.name}#find_or_create_job_status_started" if verbose
    @job_status
  end

  def job_status
    @job_status # ||= job_status_init
  end

  # def job_status_init
  #   ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
  #                                          ::Deepblue::LoggingHelper.called_from,
  #                                          "" ] if ABSTRACT_INGEST_JOB_DEBUG_VERBOSE
  #   rv = IngestJobStatus.find_or_create_job_started( job: self, verbose: ABSTRACT_INGEST_JOB_DEBUG_VERBOSE )
  #   return rv
  # end

  def log_error( msg )
    job_status.reload if job_status.present?
    Rails.logger.error msg
    job_status.add_error! msg if job_status.present?
  end

end
